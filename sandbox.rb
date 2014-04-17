
require_relative 'lib/myco/toolset'
require_relative 'lib/myco/parser'
require_relative 'lib/myco/compiler'
require_relative 'lib/myco/eval'

require 'pp'

class A
  def initialize *args
  end
end

a = Myco.eval "Object.new"

pp a
