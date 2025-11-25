module Gera
  class Engine < ::Rails::Engine
    isolate_namespace Gera

    paths.add "app/workers",          eager_load: true
    paths.add "app/authorizers",          eager_load: true

    # Идея отсюда - https://github.com/thoughtbot/factory_bot_rails/pull/149/files?diff=split&short_path=04c6e90
    #
    initializer 'gera.factories', after: 'factory_bot.set_factory_paths' do
      FactoryBot.definition_file_paths << File.expand_path('../../../factories', __FILE__) if defined?(FactoryBot)
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'factories'
    end
  end
end
