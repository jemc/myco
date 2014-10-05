
require File.expand_path('lib/myco/version', File.dirname(__FILE__))


Gem::Specification.new do |s|
  s.name          = 'myco'
  s.version       = Myco::MYCO_VERSION
  s.date          = '2014-09-11'
  s.summary       = 'A toy language built atop the Rubinius VM'
  s.description   = 'A toy language built atop the Rubinius VM'
  s.authors       = ['Joe McIlvain']
  s.email         = 'joe.eli.mac@gmail.com'
  
  s.files         = Dir['{lib}/**/*{.rb,.my}', 'bin/*', 'LICENSE', '*.md']
  s.executables   = ['myco']
  
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/myco/'
  s.licenses      = 'Copyright 2013-2014 Joe McIlvain. All rights reserved.'
  
  Myco::MYCO_REQUIRED_GEMS.each do |name, version|
    s.add_dependency name, version
  end
  
  s.add_development_dependency 'kpeg',       '~>  1.0'
  s.add_development_dependency 'racc',       '~>  1.4'
  s.add_development_dependency 'bundler',    '~>  1.6'
  s.add_development_dependency 'rake',       '~> 10.3'
  s.add_development_dependency 'pry',        '~>  0.9'
  s.add_development_dependency 'pry-rescue', '~>  1.4'
  s.add_development_dependency 'rspec',      '~>  3.0'
  s.add_development_dependency 'rspec-its',  '~>  1.0'
  s.add_development_dependency 'fivemat',    '~>  1.3'
end
