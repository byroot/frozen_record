module FrozenRecord
  module Backends
    module Json
      extend self

      def filename(model_name)
        "#{model_name.underscore.pluralize}.json"
      end

      def load(file_path)
        json_data = File.read(file_path)
        JSON.parse(json_data, symbolize_names: true) || []
      end
    end
  end
end
