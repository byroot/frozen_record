# frozen_string_literal: true
require 'csv'

module FrozenRecord
  module Backends
    module Csv
      extend self

      def filename(model_name)
        "#{model_name.underscore.pluralize}.csv"
      end

      def load(file_path)
        csv_data = File.read(file_path)
        CSV.parse(csv_data, headers: true, nil_value: '').map.with_index do |row, index|
          row.to_h.merge("position" => index)
        end
      end
    end
  end
end
