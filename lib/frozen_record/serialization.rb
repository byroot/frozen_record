# frozen_string_literal: true

require 'frozen_record/base'

module FrozenRecord
  class Base
    include ActiveModel::Serializers::JSON

    if defined? ActiveModel::Serializers::Xml
      include ActiveModel::Serializers::Xml
    end
  end
end
