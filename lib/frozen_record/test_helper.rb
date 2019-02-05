module FrozenRecord
  module TestHelper
    NoFixturesLoaded = Class.new(StandardError)

    def self.load_fixture(model_class, alternate_base_path)
      @cache ||= {}

      ensure_model_class_is_frozenrecord(model_class)

      @cache[model_class] = {
        old_base_path: model_class.base_path,
        old_auto_reloading: model_class.auto_reloading,
      }

      model_class.auto_reloading = true
      model_class.base_path = alternate_base_path
    end

    def self.unload_fixtures
      if !defined?(@cache) || !@cache.present?
        raise NoFixturesLoaded, "`unload_fixtures` was called before any calls to `load_fixture`"
      end

      @cache.each do |model_class, cached_values|
        ensure_model_class_is_frozenrecord(model_class)

        model_class.base_path = cached_values[:old_base_path]
        model_class.load_records
        model_class.auto_reloading = cached_values[:old_auto_reloading]
      end

      @cache = nil
    end

    def self.ensure_model_class_is_frozenrecord(model_class)
      return if model_class < FrozenRecord::Base
      raise ArgumentError, "Model class (#{model_class}) does not inherit from #{FrozenRecord::Base}"
    end
    private_class_method :ensure_model_class_is_frozenrecord
  end
end
