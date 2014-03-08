require 'set'

module FrozenRecord
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml

    FALSY_VALUES = [false, nil, 0, ''].to_set

    class_attribute :base_path

    class_attribute :primary_key
    self.primary_key = :id

    attribute_method_suffix '?'

    class << self

      def all
        @scope ||= Scope.new(load_records)
      end

      delegate :find, :find_by_id, :where, :first, :last, :pluck, :order, :limit, :offset,
               :minimum, :maximum, :average, :sum, to: :all

      private

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
            attributes.add(key.to_sym)
          end
        end
        attributes
      end

      def define_attributes!(attributes)
        attributes.each do |attr|
          define_attribute_method(attr)
        end
      end

      def file_path
        raise "You must define `#{name}.base_path`" unless base_path
        File.join(base_path, "#{name.underscore.pluralize}.yml")
      end

    end

    attr_reader :attributes

    def initialize(attrs = {})
      @attributes = attrs.symbolize_keys
    end

    def id
      self[primary_key]
    end

    def [](attr)
      @attributes[attr.to_sym]
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
