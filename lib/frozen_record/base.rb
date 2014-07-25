require 'set'

module FrozenRecord
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml

    FIND_BY_PATTERN = /\Afind_by_(\w+)(!?)/
    FALSY_VALUES = [false, nil, 0, ''].to_set

    class_attribute :base_path

    class_attribute :primary_key
    self.primary_key = :id

    attribute_method_suffix '?'

    class ThreadSafeStorage

      def initialize(key)
        @thread_key = key
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

      def current_scope
        store[:scope] ||= Scope.new(self, load_records)
      end
      alias_method :all, :current_scope

      def current_scope=(scope)
        store[:scope] = scope
      end

      delegate :find, :find_by_id, :where, :first, :first!, :last, :last!, :pluck, :order, :limit, :offset,
               :minimum, :maximum, :average, :sum, to: :current_scope

      def file_path
        raise "You must define `#{name}.base_path`" unless base_path
        File.join(base_path, "#{name.underscore.pluralize}.yml")
      end

      def respond_to_missing?(name, *)
        if name.to_s =~ FIND_BY_PATTERN
          return true if $1.split('_and_').all? { |attr| public_method_defined?(attr) }
        end
      end

      private

      def store
        @store ||= ThreadSafeStorage.new(name)
      end

      def method_missing(name, *args)
        if name.to_s =~ FIND_BY_PATTERN
          return dynamic_match($1, args, $2.present?)
        end
        super
      end

      def dynamic_match(expression, values, bang)
        results = where(expression.split('_and_').zip(values))
        bang ? results.first! : results.first
      end

      def load_records
        @records ||= begin
          records = YAML.load_file(file_path) || []
          define_attributes!(list_attributes(records))
          records.map(&method(:new)).freeze
        end
      end

      def list_attributes(records)
        attributes = Set.new
        records.each do |record|
          record.keys.each do |key|
            attributes.add(key.to_s)
          end
        end
        attributes
      end

      def define_attributes!(attributes)
        attributes.each do |attr|
          define_attribute_method(attr)
        end
      end

    end

    attr_reader :attributes

    def initialize(attrs = {})
      @attributes = attrs.stringify_keys
    end

    def id
      self[primary_key]
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

  end
end
