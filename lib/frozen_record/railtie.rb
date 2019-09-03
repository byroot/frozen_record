module FrozenRecord
  class Railtie < Rails::Railtie
    initializer "frozen_record.setup" do |app|
      app.config.eager_load_namespaces << FrozenRecord
    end
  end
end
