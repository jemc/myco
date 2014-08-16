
module CodeTools
  class Parser < Melbourne
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

require_relative 'parser/ast'
require_relative 'parser/peg_parser'

module CodeTools
  class Parser
    include CodeTools::AST::ProcessorMethods
    
    def parse_string string
      @peg_parser = Myco::ToolSet::PegParser.new string
      @peg_parser.processor = self
      
      if @peg_parser.parse
        return @peg_parser.root_node
      else
        @peg_parser.show_error(io=StringIO.new)
        raise SyntaxError, io.string
      end
    end
    
  end
end
