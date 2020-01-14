# frozen_string_literal: true

module FrozenRecord
  module Backends
    module Yaml
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

          YAML.load(yml_data) || []
        else
          if file_path.end_with?('.erb')
            YAML.load(ERB.new(File.read(file_path)).result) || []
          else
            YAML.load_file(file_path) || []
          end
        end
      end
    end
  end
end
