
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
  
  class PegParserWrapper
    def parse string
      @parser = Myco::ToolSet::PegParser.new string
      @parser.builder = Myco::ToolSet::AST::Builder.new
      @parsed_okay = !!@parser.parse
    end
    
    def result
      { root: @parser.root_node } if @parsed_okay
    end
    
    def raise_error
      @parser.show_error(io=StringIO.new)
      raise SyntaxError, io.string
    end
  end
  
  class Parser
    Implementation = PegParserWrapper
    
    def parse_string string
      @parser = Implementation.new
      @parser.parse(string)
      @parser.result ? @parser.result.fetch(:root) : @parser.raise_error
    end
  end
  
end
