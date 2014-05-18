
require_relative 'lib/myco/toolset'
require_relative 'lib/myco/parser'
require_relative 'lib/myco/eval'

require 'pp'

module Myco
  
  Myco.eval File.read './sandbox.my'
  
end
