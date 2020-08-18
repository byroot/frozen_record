# frozen_string_literal: true

module FrozenRecord
  module Compact
    extend ActiveSupport::Concern

    module ClassMethods
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
          build_attributes_cache
          define_attribute_methods(@attributes.to_a)
          index_definitions.values.each { |index| index.build(records) }
          records.map { |r| load(r) }.freeze
        end
      end

      if ActiveModel.gem_version >= Gem::Version.new('6.1.0.alpha')
        def define_method_attribute(attr, owner:)
          owner << "attr_reader #{attr.inspect}"
        end
      else
        def define_method_attribute(attr)
          generated_attribute_methods.attr_reader(attr)
        end
      end

      attr_reader :_attributes_cache

      private

      def build_attributes_cache
        @_attributes_cache = @attributes.each_with_object({}) do |attr, cache|
          var = :"@#{attr}"
          cache[attr.to_s] = var
          cache[attr.to_sym] = var
        end
      end
    end

    def initialize(attrs = {})
      self.attributes = attrs
    end

    def attributes
      self.class.attributes.each_with_object({}) do |attr, hash|
        hash[attr] = self[attr]
      end
    end

    def [](attr)
      if var = self.class._attributes_cache[attr]
        instance_variable_get(var)
      end
    end

    private

    def attributes=(attributes)
      self.class.attributes.each do |attr|
        instance_variable_set(self.class._attributes_cache[attr], Deduplication.deep_deduplicate!(attributes[attr]))
      end
    end

    def attribute?(attribute_name)
      val = self[attribute_name]
      Base::FALSY_VALUES.exclude?(val) && val.present?
    end
  end
end
