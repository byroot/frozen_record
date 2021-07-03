# frozen_string_literal: true

module FrozenRecord
  module Backends
    module Yaml
      autoload :ERB, 'erb'

      extend self

      # Transforms the model name into a valid filename.
      #
      # @param format [String] the model name that inherits
      #   from FrozenRecord::Base
      # @return [String] the file name.
      def filename(model_name)
        "#{model_name.underscore.pluralize}.yml"
      end

      # Reads file in `file_path` and return records.
      #
      # @param format [String] the file path
      # @return [Array] an Array of Hash objects with keys being attributes.
      def load(file_path)
        if !File.exist?(file_path) && File.exist?("#{file_path}.erb")
          file_path = "#{file_path}.erb"
        end

        if FrozenRecord.deprecated_yaml_erb_backend
          yml_erb_data = File.read(file_path)
          yml_data = ERB.new(yml_erb_data).result

          unless file_path.end_with?('.erb')
            if yml_data != yml_erb_data
              basename = File.basename(file_path)
              raise "[FrozenRecord] Deprecated: `#{basename}` contains ERB tags and should be renamed `#{basename}.erb`.\nSet FrozenRecord.deprecated_yaml_erb_backend = false to enable the future behavior"
            end
          end

          load_string(yml_data)
        else
          if file_path.end_with?('.erb')
            load_string(ERB.new(File.read(file_path)).result)
          else
            load_file(file_path)
          end
        end
      end

      private

      attr_reader :load_method, :load_file_method

      @load_method = YAML.respond_to?(:unsafe_load) ? :unsafe_load : :load
      @load_file_method = YAML.respond_to?(:unsafe_load_file) ? :unsafe_load_file : :load_file

      supports_freeze = begin
        YAML.load_file(File.expand_path('../empty.json', __FILE__), freeze: true)
      rescue ArgumentError
        false
      end

      if supports_freeze
        def load_file(path)
          YAML.public_send(load_file_method, path, freeze: true) || Dedup::EMPTY_ARRAY
        end

        def load_string(yaml)
          YAML.public_send(load_method, yaml, freeze: true) || Dedup::EMPTY_ARRAY
        end
      else
        def load_file(path)
          Dedup.deep_intern!(YAML.public_send(load_file_method, path) || Dedup::EMPTY_ARRAY)
        end

        def load_string(yaml)
          Dedup.deep_intern!(YAML.public_send(load_method, yaml) || Dedup::EMPTY_ARRAY)
        end
      end
    end
  end
end
