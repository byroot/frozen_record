# frozen_string_literal: true

module FrozenRecord
  module TestHelper
    NoFixturesLoaded = Class.new(StandardError)

    class << self
      def load_fixture(model_class, alternate_base_path)
        @cache ||= {}

        ensure_model_class_is_frozenrecord(model_class)

        return if @cache.key?(model_class)

        @cache[model_class] = base_path_if_file_present(model_class)

        model_class.base_path = alternate_base_path
        model_class.load_records(force: true)
      end

      def unload_fixture(model_class)
        return unless defined?(@cache) && @cache

        ensure_model_class_is_frozenrecord(model_class)

        return unless @cache.key?(model_class)

        old_base_path = @cache[model_class]
        if old_base_path
          model_class.base_path = old_base_path
          model_class.load_records(force: true)
        end
        @cache.delete(model_class)
      end

      def unload_fixtures
        return unless defined?(@cache) && @cache

        @cache.keys.each { |model_class| unload_fixture(model_class) }
      end

      private

      # Checks for the existence of the file for the frozen_record in the default directory.
      # Returns the base_path if the file is present, otherwise nil.
      # Some tests define specific test classes that do ONLY exist in the alternate directory.
      # As `unload_fixture(s)` tries to force load the default file, it would raise an error for
      # the "test only" fixtures. The nil value in the cache handles that case gracefully.
      def base_path_if_file_present(model_class)
        if File.exists?(model_class.file_path)
          model_class.base_path
        else
          nil
        end
      end

      def ensure_model_class_is_frozenrecord(model_class)
        unless model_class < FrozenRecord::Base
          raise ArgumentError, "Model class (#{model_class}) does not inherit from #{FrozenRecord::Base}"
        end
      end
    end
  end
end
