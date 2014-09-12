
Gem::Specification.new do |s|
  s.name          = 'myco'
  s.version       = '0.1.0dev'
  s.date          = '2014-09-11'
  s.summary       = 'A toy language built atop the Rubinius VM'
  s.description   = 'A toy language built atop the Rubinius VM'
  s.authors       = ['Joe McIlvain']
  s.email         = 'joe.eli.mac@gmail.com'
  
  s.files         = Dir['{lib}/**/*', 'bin/*', 'LICENSE', '*.md']
  
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/myco/'
  s.licenses      = 'Copyright 2013-2014 Joe McIlvain. All rights reserved.'
  
  s.add_dependency 'kpeg',               '~> 1.0'
  s.add_dependency 'racc',               '~> 1.4'
  s.add_dependency 'rubinius-bridge',    '~> 1.1'
  s.add_dependency 'rubinius-toolset',   '~> 2.3'
  s.add_dependency 'rubinius-melbourne', '~> 2.2'
  s.add_dependency 'rubinius-processor', '~> 2.2'
  s.add_dependency 'rubinius-compiler',  '~> 2.2'
  s.add_dependency 'rubinius-ast',       '~> 2.2'

  s.add_development_dependency 'bundler',    '~>  1.6'
  s.add_development_dependency 'rake',       '~> 10.3'
  s.add_development_dependency 'pry',        '~>  0.9'
  s.add_development_dependency 'pry-rescue', '~>  1.4'
  s.add_development_dependency 'rspec',      '~>  3.0'
  s.add_development_dependency 'rspec-its',  '~>  1.0'
  s.add_development_dependency 'fivemat',    '~>  1.3'
end
