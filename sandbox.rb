
require_relative 'lib/myco/toolset'
require_relative 'lib/myco/parser'
require_relative 'lib/myco/compiler'
require_relative 'lib/myco/eval'

require 'pp'

module Foo; end
module Bar; end
module Baz; end

class Component < Module
  def self.new components
    super().tap do |this|
      components.each do |other|
        this.include other
      end
    end
  end
end

class Myco
  Myco.eval "A: Foo,Bar,Baz { }"
end

p Myco::A.ancestors

pp Myco::A
