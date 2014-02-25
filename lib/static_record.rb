require 'static_record/version'
require 'active_support/all'
require 'active_model'

module StaticRecord
  RecordNotFound = Class.new(StandardError)

  class Scope

    def initialize(records)
      @records = records
    end

    def find_by_id(id)
      @records.find { |r| r.id == id }
    end

    def find(id)
      raise RecordNotFound, "Can't lookup record without ID" unless id
      find_by_id(id) or raise RecordNotFound, "Couldn't find a record with ID = #{id.inspect}"
    end

    def where(criterias)
      @records.select do |record|
        criterias.each_pair.all? { |attr, value| record.public_send(attr) == value }
      end
    end

  end

  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml

    class_attribute :base_path

    class_attribute :primary_key
    self.primary_key = :id

    class << self

      def all
        @scope ||= Scope.new(load_records)
      end

      delegate :find, :find_by_id, :where, to: :all

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

    def persisted?
      true
    end

    def to_key
      [id]
    end

    private

    def method_missing(method_name, *args)
      return super unless @attributes.has_key?(method_name)

      @attributes[method_name]
    end

  end
end
