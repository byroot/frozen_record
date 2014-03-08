module StaticRecord
  class Scope
    BLACKLISTED_ARRAY_METHODS = [
      :compact!, :flatten!, :reject!, :reverse!, :rotate!, :map!,
      :shuffle!, :slice!, :sort!, :sort_by!, :delete_if,
      :keep_if, :pop, :shift, :delete_at, :compact
    ].to_set

    delegate :length, :collect, :map, :each, :all?, :include?, :to_ary, to: :to_a

    def initialize(records)
      @records = records
      @where_values = []
    end

    def find_by_id(id)
      @records.find { |r| r.id == id }
    end

    def find(id)
      raise RecordNotFound, "Can't lookup record without ID" unless id
      find_by_id(id) or raise RecordNotFound, "Couldn't find a record with ID = #{id.inspect}"
    end

    def to_a
      @results ||= query_results
    end

    def pluck(*attributes)
      case attributes.length
      when 1
        to_a.map(&attributes.first)
      when 0
        raise NotImplementedError, '`.pluck` without arguments is not supported yet'
      else
        to_a.map { |r| attributes.map { |a| r[a] }}
      end
    end

    def exists?
      !empty?
    end

    def where(criterias)
      spawn.where!(criterias)
    end

    def respond_to_missing(method_name, *)
      array_delegable?(method_name) || super
    end

    protected

    def spawn
      clone.clear_cache!
    end

    def clear_cache!
      @results = nil
      self
    end

    def query_results
      criterias = @where_values.map(&:to_a).flatten(1)
      @records.select do |record|
        criterias.all? { |attr, value| record[attr] == value }
      end
    end

    def method_missing(method_name, *args, &block)
      return super unless array_delegable?(method_name)

      to_a.public_send(method_name, *args, &block)
    end

    def array_delegable?(method)
      Array.method_defined?(method) && BLACKLISTED_ARRAY_METHODS.exclude?(method)
    end

    def where!(criterias)
      @where_values += [criterias]
      self
    end

  end
end
