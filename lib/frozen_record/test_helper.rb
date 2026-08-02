# frozen_string_literal: true

module FrozenRecord
  module TestHelper
    FixtureAttributeMismatch = Class.new(StandardError)
    NoFixturesLoaded = Class.new(StandardError)

    class << self
      def load_fixture(model_class, alternate_base_path)
        @cache ||= {}

        ensure_model_class_is_frozenrecord(model_class)

        if @cache.key?(model_class)
          return if model_class.base_path.to_s == alternate_base_path.to_s
          unload_fixture(model_class)
        end

        old_base_path = base_path_if_file_present(model_class)
        expected_attributes = model_class.attributes if old_base_path
        @cache[model_class] = old_base_path

        model_class.base_path = alternate_base_path
        model_class.load_records(force: true)
        ensure_fixture_attributes_match(model_class, expected_attributes) if expected_attributes
      rescue FixtureAttributeMismatch
        unload_fixture(model_class)
        raise
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
        if File.exist?(model_class.file_path)
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

      def ensure_fixture_attributes_match(model_class, expected_attributes)
        actual_attributes = model_class.attributes
        missing_attributes = expected_attributes - actual_attributes
        unexpected_attributes = actual_attributes - expected_attributes
        return if missing_attributes.empty? && unexpected_attributes.empty?

        differences = []
        differences << "missing: #{missing_attributes.to_a.sort.join(', ')}" unless missing_attributes.empty?
        differences << "unexpected: #{unexpected_attributes.to_a.sort.join(', ')}" unless unexpected_attributes.empty?

        raise FixtureAttributeMismatch, "#{model_class} fixture attributes do not match (#{differences.join('; ')})"
      end
    end
  end
end
