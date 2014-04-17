
require 'myco/toolset'
require 'myco/parser'


describe Myco::ToolSet::Parser do
  
  def self.parse string, print=false, &block
    expected = block.call if block
    
    describe expected do
      it "is parsed from code: \n\n#{string}\n\n" do
        ast = Myco::ToolSet::Parser.new('(eval)', 1, []).parse_string string
        (puts; pp ast) if print
        ast.to_sexp.should eq expected if expected
      end
    end
  end
  
  
  describe "Constants" do
    
    parse "Object"  do  [:const, :Object]   end
    parse "OBJECT"  do  [:const, :OBJECT]   end
    parse "Obj_3cT" do  [:const, :Obj_3cT]  end
    
  end
  
end
