
module Myco
  MYCO_VERSION = '0.1.8'
  
  MYCO_REQUIRED_GEMS = [
    ['rubinius-toolset',   '~> 2.3'],
    ['rubinius-compiler',  '~> 2.2'],
  ]
  
  # TODO: move elsewhere?
  def self.activate_required_gems
    MYCO_REQUIRED_GEMS.each do |name, version|
      gem name, version
    end
  end
end
