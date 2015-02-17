
require 'stringio'

module CodeTools
  class Parser < Melbourne
  end
  
  class Compiler
    module ParserPatch
      def initialize *args
        super
        @processor = Myco::ToolSet::Parser
      end
    end
    
    Parser.prepend ParserPatch
  end
end

require_relative 'parser/ast'
require_relative 'parser/peg_parser'

module CodeTools
  
  class AST::Builder
    include CodeTools::AST::BuilderMethods
  end
  
  class Parser
    def parse_string string
      @peg_parser = Myco::ToolSet::PegParser.new string
      @peg_parser.builder = Myco::ToolSet::AST::Builder.new
      
      if @peg_parser.parse
        return @peg_parser.root_node
      else
        @peg_parser.show_error(io=StringIO.new)
        raise SyntaxError, io.string
      end
    end
  end
  
end
