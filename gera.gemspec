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
  s.add_runtime_dependency 'require_all'

  s.add_development_dependency "sqlite3"
end
