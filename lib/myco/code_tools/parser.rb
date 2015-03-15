
require 'stringio'


# TODO: try to load Pegleromyces library in a better way
Pegleromyces = Myco.eval_file(
  'parser/pegleromyces/lib/pegleromyces.my', nil, false)


module CodeTools
  
  class AST::Builder
    include CodeTools::AST::BuilderMethods
  end
  
  class Parser
    # TODO: convert this section to Myco and make idiomatic
    MycoParser = Myco::Component.new([Pegleromyces::BytecodeParser]).instance
    MycoBuilder = Myco.eval_file('parser/MycoBuilder.my')
    
    MycoBuilder.ast = CodeTools::AST::Builder.new
    MycoParser.component.declare_meme(:new_builder) { MycoBuilder }
    MycoParser.component.declare_meme(:new) { MycoParser }
    
    MycoParser.grammar = Myco.eval_file('parser/MycoGrammar.my')
    
    Implementation = MycoParser
    
    def parse_string string
      @parser = Implementation.new
      @parser.parse(string)
      @parser.result ? @parser.result.fetch(:root) : @parser.raise_error
    end
  end
  
end
