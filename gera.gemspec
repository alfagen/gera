$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "gera/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
    s.name        = "gera"
    s.version     = GERA::VERSION
    s.authors     = ["Danil Pismenny"]
    s.email       = ["danil@brandymint.ru"]
    s.homepage    = ""
    s.summary       = %q{Exchange Rate Generator}
    s.description   = %q{Service to import and generate own rates}
    s.license     = "MIT"

    s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

    s.add_dependency "rails", "~> 5.2.1"
    s.add_dependency 'virtus'
    s.add_dependency 'crypto_math', '~> 0.1.2'
    s.add_dependency 'require_all'
    s.add_dependency 'rest-client', '~> 2.0'
    s.add_dependency 'sidekiq'
    s.add_dependency 'auto_logger', '~> 0.1.3'
    s.add_dependency 'request_store'
    s.add_dependency 'business_time'
    s.add_dependency 'dapi-archivable'

    s.add_development_dependency 'rubocop'
    s.add_development_dependency 'rubocop-rspec'
    s.add_development_dependency 'guard-bundler'
    s.add_development_dependency 'guard-ctags-bundler'
    s.add_development_dependency 'guard-rspec'
    s.add_development_dependency 'guard-rubocop'
    s.add_development_dependency 'pry'
    s.add_development_dependency 'pry-doc'
    # Call 'byebug' anywhere in the code to stop execution and get a debugger console
    s.add_development_dependency 'byebug'
    # Добавляет show-routes и show-models
    # и делает рельсовую конслоль через pry
    s.add_development_dependency 'pry-rails'

    # show-method
    # hist --grep foo
    # Adds step-by-step debugging and stack navigation capabilities to pry using byebug.
    s.add_development_dependency 'pry-byebug'

    s.add_development_dependency 'factory_bot'
    s.add_development_dependency 'factory_bot_rails'
    s.add_development_dependency 'rspec-rails', '~> 3.7'
    s.add_development_dependency 'database_rewinder'
    s.add_development_dependency 'mysql2'
    s.add_development_dependency 'vcr'
    s.add_development_dependency 'webmock'
    s.add_development_dependency 'timecop'
end
