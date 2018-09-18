module Gera
  class Engine < ::Rails::Engine
    isolate_namespace Gera

    # config.autoload_paths << File.expand_path("lib/some/path", __dir__)

    paths.add "app/workers",          eager_load: true

    config.factory_bot.definition_file_paths = FACTORY_PATH if defined?(FactoryBotRails)
  end
end
