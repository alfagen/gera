begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Gera'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load 'rails/tasks/engine.rake'

load 'rails/tasks/statistics.rake'

require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec
rescue LoadError
  puts 'no rspec available'
end

load 'lib/tasks/auto_generate_diagram.rake'

if defined? YARD
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb', 'app/**/*.rb']  # optional
    t.options = ['--any', '--extra', '--opts'] # optional
    t.stats_options = ['--list-undoc']         # optional
  end
end
