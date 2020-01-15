# frozen_string_literal: true

require 'active_support/core_ext/object/duplicable'

module FrozenRecord
  module Deduplication
    extend self

    # We deduplicate data in place because it is assumed it directly
    # comes from the parser, and won't be held by anyone.
    #
    # Frozen Hashes and Arrays are ignored because they are likely
    # the result of the use of YAML anchor. Meaning we already deduplicated
    # them.
    if RUBY_VERSION >= '2.7'
      def deep_deduplicate!(data)
        case data
        when Hash
          return data if data.frozen?
          data.transform_keys! { |k| deep_deduplicate!(k) }
          data.transform_values! { |v| deep_deduplicate!(v) }
          data.freeze
        when Array
          return data if data.frozen?
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
          return data if data.frozen?
          data.transform_keys! { |k| deep_deduplicate!(k) }
          data.transform_values! { |v| deep_deduplicate!(v) }
          data.freeze
        when Array
          return data if data.frozen?
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
