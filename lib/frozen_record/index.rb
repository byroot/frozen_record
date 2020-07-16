# frozen_string_literal: true

module FrozenRecord
  class Index
    EMPTY_ARRAY = [].freeze
    private_constant :EMPTY_ARRAY

    AttributeNonUnique = Class.new(StandardError)

    attr_reader :attribute, :model

    def initialize(model, attribute, unique: false)
      @model = model
      @attribute = -attribute.to_s
      @index = nil
    end

    def unique?
      false
    end

    def query(value)
      case value
      when Array, Range
        lookup_multi(value)
      else
        lookup(value)
      end
    end

    def lookup_multi(values)
      values.flat_map { |v| lookup(v) }
    end

    def lookup(value)
      @index.fetch(value, EMPTY_ARRAY)
    end

    def reset
      @index = nil
    end

    def build(records)
      @index = records.each_with_object({}) do |record, index|
        entry = (index[record[attribute]] ||= [])
        entry << record
      end
      @index.values.each(&:freeze)
      @index.freeze
    end
  end

  class UniqueIndex < Index
    def unique?
      true
    end

    def lookup_multi(values)
      results = @index.values_at(*values)
      results.compact!
      results
    end

    def lookup(value)
      record = @index[value]
      record ? [record] : EMPTY_ARRAY
    end

    def build(records)
      @index = records.to_h { |r| [r[attribute], r] }
      if @index.size != records.size
        raise AttributeNonUnique, "#{model}##{attribute.inspect} is not unique."
      end
      @index.freeze
    end
  end
end
