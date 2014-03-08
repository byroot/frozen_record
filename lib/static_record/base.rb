module StaticRecord
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml

    FALSY_VALUES = [false, nil, 0, ''].to_set

    class_attribute :base_path

    class_attribute :primary_key
    self.primary_key = :id

    class << self

      def all
        @scope ||= Scope.new(load_records)
      end

      delegate :find, :find_by_id, :where, :first, :last, :pluck, to: :all

      private

      def load_records
        records = YAML.load_file(file_path) || []
        records.map(&method(:new)).freeze
      end

      def file_path
        File.join(base_path, "#{name.underscore.pluralize}.yml")
      end

    end

    def initialize(attrs = {})
      @attributes = attrs.symbolize_keys
    end

    def id
      @attributes[primary_key.to_sym]
    end

    def [](attr)
      @attributes[attr.to_sym]
    end

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

    def query_attribute(attribute_name)
      FALSY_VALUES.exclude?(self[attribute_name]) && self[attribute_name].present?
    end

    def method_missing(method_name, *args)
      if method_name.to_s =~ /(.*)(\?)/
        return query_attribute($1.to_sym)
      end

      return super unless @attributes.has_key?(method_name)

      @attributes[method_name]
    end

  end
end
