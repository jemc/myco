
source 'https://rubygems.org'

gem 'myco' # Depends on a version of myco to build itself

require 'rubygems'

gemspec = Gem::Specification::load("myco.gemspec")
gemspec.dependencies.each do |dep|
  gem dep.name, dep.requirement.to_s
end
