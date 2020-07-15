# frozen_string_literal: true

require 'set'
require 'active_support/descendants_tracker'
require 'frozen_record/backends'
require 'objspace'

module FrozenRecord
  class Base
    extend ActiveSupport::DescendantsTracker
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods
    include ActiveModel::Serializers::JSON

    if defined? ActiveModel::Serializers::Xml
      include ActiveModel::Serializers::Xml
    end

    FIND_BY_PATTERN = /\Afind_by_(\w+)(!?)/
    FALSY_VALUES = [false, nil, 0, -''].to_set

    class_attribute :base_path, :primary_key, :backend, :auto_reloading, :default_attributes, instance_accessor: false
    class_attribute :index_definitions, instance_accessor: false, default: {}.freeze

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
      alias_method :set_default_attributes, :default_attributes=
      private :set_default_attributes
      def default_attributes=(default_attributes)
        set_default_attributes(Deduplication.deep_deduplicate!(default_attributes.stringify_keys))
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

      delegate :find, :find_by_id, :find_by, :find_by!, :where, :first, :first!, :last, :last!, :pluck, :ids, :order, :limit, :offset,
               :minimum, :maximum, :average, :sum, :count, to: :current_scope

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
          records.each { |r| assign_defaults!(r) }
          records = Deduplication.deep_deduplicate!(records)
          @attributes = list_attributes(records).freeze
          define_attribute_methods(@attributes.to_a)
          records = records.map { |r| load(r) }.freeze
          index_definitions.values.each { |index| index.build(records) }
          records
        end
      end

      def scope(name, body)
        unless body.respond_to?(:call)
          raise ArgumentError, "The scope body needs to be callable."
        end
        singleton_class.send(:define_method, name) { |*args| body.call(*args) }
      end

      alias_method :load, :new
      private :load

      def new(attrs = {})
        load(assign_defaults!(attrs.stringify_keys))
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
          attributes.merge(record.keys)
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
      super || other.is_a?(self.class) && other.id == id
    end

    def persisted?
      true
    end

    def to_key
      [id]
    end

    private

    def attribute?(attribute_name)
      FALSY_VALUES.exclude?(self[attribute_name]) && self[attribute_name].present?
    end

    def attribute_method?(attribute_name)
      respond_to_without_attributes?(:attributes) && self.class.attributes.include?(attribute_name)
    end
  end
end
