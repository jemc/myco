
require_relative 'myco/toolset'
require_relative 'myco/parser'
require_relative 'myco/compiler'
require_relative 'myco/eval'

require 'pp'

class A
  def initialize *args
  end
end

a = Myco.eval "Object.new"

pp a
