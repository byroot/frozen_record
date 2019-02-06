module FrozenRecord
  module TestHelper
    NoFixturesLoaded = Class.new(StandardError)

    class << self
      def load_fixture(model_class, alternate_base_path)
        @cache ||= {}

        ensure_model_class_is_frozenrecord(model_class)

        return if @cache.key?(model_class)

        @cache[model_class] = {
          old_base_path: model_class.base_path,
          old_auto_reloading: model_class.auto_reloading,
        }

        model_class.auto_reloading = true
        model_class.base_path = alternate_base_path
      end

      def unload_fixtures
        @cache.each do |model_class, cached_values|
          model_class.base_path = cached_values[:old_base_path]
          model_class.load_records
          model_class.auto_reloading = cached_values[:old_auto_reloading]
        end

        @cache = nil
      end

      private

      def ensure_model_class_is_frozenrecord(model_class)
        return if model_class < FrozenRecord::Base
        raise ArgumentError, "Model class (#{model_class}) does not inherit from #{FrozenRecord::Base}"
      end
    end
  end
end
