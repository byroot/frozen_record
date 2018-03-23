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
        yml_erb_data = File.read(file_path)
        yml_data = ERB.new(yml_erb_data).result

        YAML.load(yml_data) || []
      end
    end
  end
end
