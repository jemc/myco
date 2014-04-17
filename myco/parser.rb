
module Myco::ToolSet
  class Parser < Rubinius::ToolSets::Runtime::Melbourne
  end
  
  class Compiler
    class Parser
      
      old_init = instance_method :initialize
      
      define_method :initialize do |*args|
        old_init.bind(self).call *args
        @processor = Myco::ToolSet::Parser
      end
    end
  end
end

require_relative 'parser/lexer'

module Myco::ToolSet
  class Parser
    
    def parse_string string
      klass     = AST::ConstantAccess.new    1, :A
      sendwargs = AST::SendWithArguments.new 1, klass, :new, nil
      
      sendwargs
    end
    
  end
end
