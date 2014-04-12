
require_relative 'myco/toolset'
require_relative 'myco/compiler'
require_relative 'myco/eval'

module Myco::ToolSet
  module AST
    class InstanceVariableAssignment
      def bytecode(g)
        @value.bytecode(g) if @value

        pos(g)
        
        # Call Myco.updated object, name, value
        g.dup_top
        g.push_const :Myco
        g.rotate 2
        g.push_literal @name
        g.push_self
        g.rotate 3
        g.send :updated, 3, false
        g.pop
        # Resume normal operation
        
        g.set_ivar @name
      end
    end
  end
end

class Myco
  def self.updated object, name, value
    puts "#{object} #{name.inspect} = #{value.inspect}"
  end
end

Myco.eval "Object.new.instance_eval { @thing = 88; @thing = 99 }"
