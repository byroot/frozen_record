# frozen_string_literal: true

module FrozenRecord
  module Deduplication
    extend self

    if RUBY_VERSION >= '2.7'
      def deep_deduplicate!(data)
        case data
        when Hash
          data.transform_keys! { |k| deep_deduplicate!(k) }
          data.transform_values! { |v| deep_deduplicate!(v) }
          data.freeze
        when Array
          data.map! { |d| deep_deduplicate!(d) }.freeze
        when String
          -data
        else
          data.duplicable? ? data.freeze : data
        end
      end
    else
      def deep_deduplicate!(data)
        case data
        when Hash
          data.transform_keys! { |k| deep_deduplicate!(k) }
          data.transform_values! { |v| deep_deduplicate!(v) }
          data.freeze
        when Array
          data.map! { |d| deep_deduplicate!(d) }.freeze
        when String
          # String#-@ doesn't deduplicate the string if it's tainted.
          # So in such case we need to untaint it first.
          if data.tainted?
            -(+data).untaint
          else
            -data
          end
        else
          data.duplicable? ? data.freeze : data
        end
      end
    end
  end
end
