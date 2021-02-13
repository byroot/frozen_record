# frozen_string_literal: true

module FrozenRecord::Reflection
  extend ActiveSupport::Concern

  included do
    class_attribute :frozen_reflections, instance_writer: false, default: {}
  end

  class << self
    def create(macro, name, scope, options, ar)
      reflection_class_for(macro).new(name, scope, options, ar)
    end

    def add_reflection(ar, name, reflection)
      ar.frozen_reflections[name.to_s] = reflection
    end

    def define_accessors(ar, name, reflection)
      instance_variable_name = "@#{name}"

      # Reader
      ar.define_method(name) do
        if instance_variable_defined?(instance_variable_name)
          return instance_variable_get(instance_variable_name)
        end

        foreign_key_value = send(reflection.foreign_key)
        value =
          if reflection.collection?
            reflection.klass.where(reflection.primary_key => foreign_key_value)
          else
            reflection.klass.find_by(reflection.primary_key => foreign_key_value)
          end

        instance_variable_set(instance_variable_name, value)
      end

      # Writer
      ar.define_method("#{name}=") do |value|
        foreign_key_value =
          if reflection.collection?
            Array.wrap(value).map { |item| item.try(reflection.primary_key) }.compact
          else
            value.try(reflection.primary_key)
          end

        send("#{reflection.foreign_key}=", foreign_key_value)
        instance_variable_set(instance_variable_name, value)
      end
    end

    private

    def reflection_class_for(macro)
      case macro
      when :belongs_to
        BelongsToReflection
      when :belongs_to_many
        BelongsToManyReflection
      else
        raise "Unsupported Macro: #{macro}"
      end
    end
  end

  module ClassMethods
    def reflect_on_all_frozen_associations(macro = nil)
      association_reflections = frozen_reflections.values
      association_reflections.select! { |reflection| reflection.macro == macro } if macro
      association_reflections
    end

    def belongs_to_frozen(name, **options)
      reflection = FrozenRecord::Reflection.create(:belongs_to, name, nil, options, self)
      FrozenRecord::Reflection.add_reflection(self, name, reflection)
      FrozenRecord::Reflection.define_accessors(self, name, reflection)
    end

    def belongs_to_many_frozen(name, **options)
      reflection = FrozenRecord::Reflection.create(:belongs_to_many, name, nil, options, self)
      FrozenRecord::Reflection.add_reflection(self, name, reflection)
      FrozenRecord::Reflection.define_accessors(self, name, reflection)
    end
  end

  class AssociationReflection
    attr_reader :name, :scope, :options, :active_record

    def initialize(name, scope, options, active_record)
      @name = name
      @scope = scope
      @options = options
      @active_record = active_record
    end

    def class_name
      @class_name ||= options.fetch(:class_name) { derive_class_name }.to_s
    end

    def foreign_key
      @foreign_key ||= options.fetch(:foreign_key) { derive_foreign_key }.to_s
    end

    def klass
      @klass ||= derive_class
    end

    def plural_name
      name.to_s.pluralize
    end

    def primary_key
      @primary_key ||= options.fetch(:primary_key) { derive_primary_key }.to_s
    end

    private

    def active_record_defines?(method_name)
      active_record.column_names.include?(method_name.to_s) ||
        active_record.instance_methods.include?(method_name.to_sym)
    end

    def derive_class
      active_record.const_get(class_name).tap do |klass|
        unless klass < FrozenRecord::Base
          raise ArgumentError, <<-MSG.squish
            Couldn't find a valid model for frozen #{name} association.
            Please provide the :class_name option on the association declaration.
            If :class_name is already provided make sure it is a FrozenRecord::Base subclass.
          MSG
        end
      end
    end

    def derive_class_name
      class_name = name.to_s
      class_name = class_name.singularize if collection?
      class_name.camelize
    end

    def derive_foreign_key
      foreign_key =
        if collection?
          "#{name.to_s.singularize}_#{primary_key.to_s.pluralize}"
        else
          "#{name}_#{primary_key}"
        end

      unless active_record_defines? foreign_key
        raise ArgumentError, <<-MSG.squish
          Couldn't determine foreign key for frozen #{name} association.
          Please provide the :foreign_key option on the association declaration
          or define #{class_name}##{foreign_key}.
        MSG
      end

      foreign_key
    end

    def derive_primary_key
      potential_primary_keys = [:id, :key] & klass.instance_methods

      # Try to choose primary key based on given or potential foreign_keys
      primary_key = potential_primary_keys.detect do |potential_primary_key|
        potential_foreign_key =
          if collection?
            "#{name.to_s.singularize}_#{potential_primary_key.to_s.pluralize}"
          else
            "#{name}_#{potential_primary_key}"
          end

        if options[:foreign_key].present?
          options[:foreign_key] == potential_foreign_key
        else
          active_record_defines? potential_foreign_key
        end
      end

      # Use the first one if we still don't know
      primary_key ||= potential_primary_keys.first

      if primary_key.blank?
        raise ArgumentError, <<-MSG.squish
          Couldn't determine primary key for frozen #{name} association.
          Please provide the :primary_key option on the association declaration.
        MSG
      end

      primary_key
    end

  end

  class BelongsToReflection < AssociationReflection
    def collection?; false; end
    def macro; :belongs_to; end
  end

  class BelongsToManyReflection < AssociationReflection
    def collection?; true; end
    def macro; :belongs_to_many; end
  end
end
