# frozen_string_literal: true

require 'active_support/descendants_tracker'
require 'frozen_record/backends'

module FrozenRecord
  SlowQuery = Class.new(StandardError)

  class << self
    attr_accessor :enforce_max_records_scan

    def ignore_max_records_scan
      previous = enforce_max_records_scan
      self.enforce_max_records_scan = false
      yield
    ensure
      self.enforce_max_records_scan = previous
    end
  end
  @enforce_max_records_scan = true

  class Base
    extend ActiveSupport::DescendantsTracker
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods

    FIND_BY_PATTERN = /\Afind_by_(\w+)(!?)/
    FALSY_VALUES = [false, nil, 0, -''].to_set

    class_attribute :base_path, :primary_key, :backend, :auto_reloading, :default_attributes, instance_accessor: false
    class_attribute :index_definitions, instance_accessor: false
    class_attribute :max_records_scan, instance_accessor: false
    self.index_definitions = {}.freeze

    self.primary_key = 'id'

    self.backend = FrozenRecord::Backends::Yaml

    attribute_method_suffix -'?'

    class ThreadSafeStorage

      def initialize(key)
        @thread_key = "#{ self.object_id }-#{ key }"
      end

      def [](key)
        Thread.current[@thread_key] ||= {}
        Thread.current[@thread_key][key]
      end

      def []=(key, value)
        Thread.current[@thread_key] ||= {}
        Thread.current[@thread_key][key] = value
      end

    end

    class << self
      def with_max_records_scan(value)
        previous_max_records_scan = max_records_scan
        self.max_records_scan = value
        yield
      ensure
        self.max_records_scan = previous_max_records_scan
      end

      alias_method :set_default_attributes, :default_attributes=
      private :set_default_attributes
      def default_attributes=(default_attributes)
        set_default_attributes(default_attributes.transform_keys(&:to_s))
      end

      alias_method :set_primary_key, :primary_key=
      private :set_primary_key
      def primary_key=(primary_key)
        set_primary_key(-primary_key.to_s)
      end

      alias_method :set_base_path, :base_path=
      private :set_base_path
      def base_path=(base_path)
       @file_path = nil
       set_base_path(base_path)
      end

      attr_accessor :abstract_class

      def attributes
        @attributes ||= begin
          load_records
          @attributes
        end
      end

      def abstract_class?
        defined?(@abstract_class) && @abstract_class
      end

      def current_scope
        store[:scope] ||= Scope.new(self)
      end
      alias_method :all, :current_scope

      def current_scope=(scope)
        store[:scope] = scope
      end

      delegate :each, :find_each, :where, :first, :first!, :last, :last!,
               :pluck, :ids, :order, :limit, :offset, :minimum, :maximum, :average, :sum, :count,
               to: :current_scope

      def file_path
        raise ArgumentError, "You must define `#{name}.base_path`" unless base_path
        @file_path ||= begin
          file_path = File.join(base_path, backend.filename(name))
          if !File.exist?(file_path) && File.exist?("#{file_path}.erb")
            "#{file_path}.erb"
          else
            file_path
          end
        end
      end

      def find_by_id(id)
        find_by(primary_key => id)
      end

      def find(id)
        raise RecordNotFound, "Can't lookup record without ID" unless id
        find_by(primary_key => id) or raise RecordNotFound, "Couldn't find a record with ID = #{id.inspect}"
      end

      def find_by(criterias)
        if criterias.size == 1
          criterias.each do |attribute, value|
            attribute = attribute.to_s
            if index = index_definitions[attribute]
              return index.lookup(value).first
            end
          end
        end
        current_scope.find_by(criterias)
      end

      def find_by!(criterias)
        find_by(criterias) or raise RecordNotFound, "No record matched"
      end

      def add_index(attribute, unique: false)
        index = unique ? UniqueIndex.new(self, attribute) : Index.new(self, attribute)
        self.index_definitions = index_definitions.merge(index.attribute => index).freeze
      end

      def memsize(object = self, seen = Set.new.compare_by_identity)
        return 0 unless seen.add?(object)

        size = ObjectSpace.memsize_of(object)
        object.instance_variables.each { |v| size += memsize(object.instance_variable_get(v), seen) }

        case object
        when Hash
          object.each { |k, v| size += memsize(k, seen) + memsize(v, seen) }
        when Array
          object.each { |i| size += memsize(i, seen) }
        end
        size
      end

      def respond_to_missing?(name, *)
        if name.to_s =~ FIND_BY_PATTERN
          load_records # ensure attribute methods are defined
          return true if $1.split('_and_').all? { |attr| instance_method_already_implemented?(attr) }
        end
      end

      def eager_load!
        return if auto_reloading || abstract_class?

        load_records
      end

      def load_records(force: false)
        if force || (auto_reloading && file_changed?)
          @records = nil
          undefine_attribute_methods
        end

        @records ||= begin
          records = backend.load(file_path)
          if default_attributes
            records = records.map { |r| assign_defaults!(r.dup).freeze }.freeze
          end
          @attributes = list_attributes(records).freeze
          define_attribute_methods(@attributes.to_a)
          records = FrozenRecord.ignore_max_records_scan { records.map { |r| load(r) }.freeze }
          index_definitions.values.each { |index| index.build(records) }
          records
        end
      end

      def scope(name, body)
        singleton_class.send(:define_method, name, &body)
      end

      alias_method :load, :new
      private :load

      def new(attrs = {})
        load(assign_defaults!(attrs.transform_keys(&:to_s)))
      end

      private

      def file_changed?
        last_mtime = @file_mtime
        @file_mtime = File.mtime(file_path)
        last_mtime != @file_mtime
      end

      def store
        @store ||= ThreadSafeStorage.new(name)
      end

      def assign_defaults!(record)
        if default_attributes
          default_attributes.each do |key, value|
            unless record.key?(key)
              record[key] = value
            end
          end
        end

        record
      end

      def method_missing(name, *args)
        if name.to_s =~ FIND_BY_PATTERN
          return dynamic_match($1, args, $2.present?)
        end
        super
      end

      def dynamic_match(expression, values, bang)
        results = where(expression.split('_and_'.freeze).zip(values))
        bang ? results.first! : results.first
      end

      def list_attributes(records)
        attributes = Set.new
        records.each do |record|
          record.each_key do |key|
            attributes.add(key)
          end
        end
        attributes
      end

    end

    def initialize(attrs = {})
      @attributes = attrs.freeze
    end

    def attributes
      @attributes.dup
    end

    def id
      self[self.class.primary_key]
    end

    def [](attr)
      @attributes[attr.to_s]
    end
    alias_method :attribute, :[]

    def ==(other)
      super || other.is_a?(self.class) && !id.nil? && other.id == id
    end

    def persisted?
      true
    end

    def to_key
      [id]
    end

    private

    def attribute?(attribute_name)
      !FALSY_VALUES.include?(self[attribute_name]) && self[attribute_name].present?
    end

    def attribute_method?(attribute_name)
      respond_to_without_attributes?(:attributes) && self.class.attributes.include?(attribute_name)
    end
  end
end
