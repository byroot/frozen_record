require 'static_record/version'
require 'active_support/all'
require 'active_model'
require 'set'

module StaticRecord
  RecordNotFound = Class.new(StandardError)

  class Scope

    BLACKLISTED_ARRAY_METHODS = [
      :compact!, :flatten!, :reject!, :reverse!, :rotate!, :map!,
      :shuffle!, :slice!, :sort!, :sort_by!, :delete_if,
      :keep_if, :pop, :shift, :delete_at, :compact
    ].to_set

    delegate :length, :collect, :map, :each, :all?, :include?, :to_ary, to: :to_a

    def initialize(records)
      @records = records
      @where_values = []
    end

    def find_by_id(id)
      @records.find { |r| r.id == id }
    end

    def find(id)
      raise RecordNotFound, "Can't lookup record without ID" unless id
      find_by_id(id) or raise RecordNotFound, "Couldn't find a record with ID = #{id.inspect}"
    end

    def to_a
      @results ||= query_results
    end

    def exists?
      !empty?
    end

    def where(criterias)
      spawn.where!(criterias)
    end

    def respond_to_missing(method_name, *)
      array_delegable?(method_name) || super
    end

    protected

    def spawn
      clone.clear_cache!
    end

    def clear_cache!
      @results = nil
      self
    end

    def query_results
      criterias = @where_values.map(&:to_a).flatten(1)
      @records.select do |record|
        criterias.all? { |attr, value| record[attr] == value }
      end
    end

    def method_missing(method_name, *args, &block)
      return super unless array_delegable?(method_name)

      to_a.public_send(method_name, *args, &block)
    end

    def array_delegable?(method)
      Array.method_defined?(method) && BLACKLISTED_ARRAY_METHODS.exclude?(method)
    end

    def where!(criterias)
      @where_values += [criterias]
      self
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

      delegate :find, :find_by_id, :where, :first, :last, to: :all

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

    def method_missing(method_name, *args)
      return super unless @attributes.has_key?(method_name)

      @attributes[method_name]
    end

  end
end
