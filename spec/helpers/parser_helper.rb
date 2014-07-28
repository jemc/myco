
module SpecHelpers
  module ParserHelper
    
    def lex string, print=false, &block
      expected = block.call if block
      describe expected do
        it "is lexed from code: \n\n#{string}\n\n" do
          tokens = Myco::ToolSet::Parser::Lexer.new(string).lex
          tokens.pop # Get rid of final T_DECLARE_END
          (puts; pp tokens) if print
          tokens.map{|x| x[0..1]}.should eq expected if expected
        end
      end
      
      this_spec = self
      
      string.instance_eval do
        define_singleton_method :parse do |expected|
          this_spec.parse string, print do expected end
        end
      end
      
      string
    end
    
    def parse string, print=false, &block
      expected = block.call if block
      
      describe expected do
        it "is parsed from code: \n\n#{string}\n\n" do
          ast = Myco::ToolSet::Parser.new('(eval)', 1, []).parse_string string
          (puts; pp ast) if print
          ast.to_sexp.last.should eq expected if expected
        end
      end
    end
    
  end
end
