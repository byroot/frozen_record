module FrozenRecord
  module TestHelper
    NoFixturesLoaded = Class.new(StandardError)

    class << self
      def load_fixture(model_class, alternate_base_path)
        @cache ||= {}

        unless model_class < FrozenRecord::Base
          raise ArgumentError, "Model class (#{model_class}) does not inherit from #{FrozenRecord::Base}"
        end

        return if @cache.key?(model_class)

        @cache[model_class] ||= model_class.base_path

        model_class.base_path = alternate_base_path
        model_class.load_records(force: true)
      end

      def unload_fixtures
        return unless defined?(@cache) && @cache

        @cache.each do |model_class, old_base_path|
          model_class.base_path = old_base_path
          model_class.load_records(force: true)
        end

        @cache = nil
      end

      private

      def ensure_model_class_is_frozenrecord(model_class)
      end
    end
  end
end
