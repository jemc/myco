
require 'myco/toolset'
require 'myco/parser'


describe Myco::ToolSet::Parser::Lexer do
  
  def self.lex string, print=false, &block
    expected = block.call if block
    describe expected do
      it "is lexed from code: \n\n#{string}\n\n" do
        tokens = Myco::ToolSet::Parser::Lexer.new(string).lex
        (puts; pp tokens) if print
        tokens.should eq expected if expected
      end
    end
  end
  
  
  lex "Object"  do  [[:T_CONSTANT, "Object", 1]]   end
  lex "OBJECT"  do  [[:T_CONSTANT, "OBJECT", 1]]   end
  lex "Obj_3cT" do  [[:T_CONSTANT, "Obj_3cT", 1]]  end
  
  lex "Object { }" do 
    [[:T_CONSTANT, "Object", 1],
     [:T_DECLARE_BEGIN, "{", 1],
     [:T_DECLARE_END, "}", 1]]
  end
  
end
