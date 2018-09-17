module GERA
  class Engine < ::Rails::Engine
    isolate_namespace GERA

    paths.add "app/workers",          eager_load: true

    config.factory_bot.definition_file_paths = File.expand_path('../spec/factories', __FILE__) if defined?(FactoryBotRails)
  end
end
