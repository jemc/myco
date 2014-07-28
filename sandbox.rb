
require_relative 'lib/myco/toolset'
require_relative 'lib/myco/parser'
require_relative 'lib/myco/eval'
require_relative 'lib/myco/bootstrap'


module Myco
  def self.myco_open path
    Myco.eval File.read(path), nil, path
  end
  
  myco_open './lib/myco/bootstrap.my'
  myco_open './sandbox.my'
end
