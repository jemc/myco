
module Myco
  MYCO_VERSION = '0.1.0.dev'
  
  MYCO_REQUIRED_GEMS = [
    ['rubinius-toolset',   '~> 2.3'],
    ['rubinius-melbourne', '~> 2.2'],
    ['rubinius-processor', '~> 2.2'],
    ['rubinius-compiler',  '~> 2.2'],
    ['rubinius-ast',       '~> 2.2'],
  ]
  
  # TODO: move elsewhere?
  def self.activate_required_gems
    MYCO_REQUIRED_GEMS.each do |name, version|
      gem name, version
    end
  end
end
