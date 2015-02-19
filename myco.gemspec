
require File.expand_path('lib/myco/version', File.dirname(__FILE__))


Gem::Specification.new do |s|
  s.name          = 'myco'
  s.version       = Myco::MYCO_VERSION
  s.date          = '2015-02-18'
  s.summary       = 'An experimental language on the Rubinius VM'
  s.description   = 'An experimental language on the Rubinius VM'
  s.authors       = ['Joe McIlvain']
  s.email         = 'joe.eli.mac@gmail.com'
  
  # Release files are managed by the `myco inoculate` command
  s.files         = Dir['**/*']
  s.executables   = Dir['bin/*'].map { |x| File.basename(x) }
  
  s.homepage      = 'https://github.com/jemc/myco/'
  s.licenses      = 'Copyright 2013-2015 Joe McIlvain. All rights reserved.'
  
  Myco::MYCO_REQUIRED_GEMS.each do |name, version|
    s.add_dependency name, version
  end
  
  s.add_development_dependency 'kpeg',       '~>  1.0'
  s.add_development_dependency 'bundler',    '~>  1.6'
  s.add_development_dependency 'rake',       '~> 10.3'
  s.add_development_dependency 'pry',        '~>  0.9'
  s.add_development_dependency 'pry-rescue', '~>  1.4'
  s.add_development_dependency 'rspec',      '~>  3.0'
  s.add_development_dependency 'fivemat',    '~>  1.3'
end
