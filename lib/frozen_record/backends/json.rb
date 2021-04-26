# frozen_string_literal: true
require 'json'

module FrozenRecord
  module Backends
    module Json
      extend self

      def filename(model_name)
        "#{model_name.underscore.pluralize}.json"
      end

      if JSON.respond_to?(:load_file)
        supports_freeze = begin
          JSON.load_file(File.expand_path('../empty.json', __FILE__), freeze: true)
        rescue ArgumentError
          false
        end

        if supports_freeze
          def load(file_path)
            JSON.load_file(file_path, freeze: true) || Dedup::EMPTY_ARRAY
          end
        else
          def load(file_path)
            Dedup.deep_intern!(JSON.load_file(file_path) || Dedup::EMPTY_ARRAY)
          end
        end
      else
        def load(file_path)
          Dedup.deep_intern!(JSON.parse(File.read(file_path)) || Dedup::EMPTY_ARRAY)
        end
      end
    end
  end
end
