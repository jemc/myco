
module SpecHelpers
  module ParserHelper
    
    def parse string, print=false, &block
      expected = block.call if block
      
      describe expected do
        it "is parsed from code: \n\n#{string}\n\n" do
          ast = Myco::ToolSet::Parser.new('(eval)', 1, []).parse_string string
          ast = ast.body # Get rid of toplevel DeclareFile node
          (puts; pp ast) if print
          ast.to_sexp.last.should eq expected if expected
        end
      end
      
      this_spec = self
      
      string.instance_eval do
        define_singleton_method :to_ruby do |ruby_string|
          this_spec.to_ruby string do ruby_string end
        end
      end
      
      string
    end
    
    def to_ruby string, &block
      expected = block.call if block
      
      # Remove all indentation for comparison
      string   = string  .gsub(/\n\s*/, "\n").strip
      expected = expected.gsub(/\n\s*/, "\n").strip
      
      describe expected do
        it "is the Ruby code generated from Myco code: \n\n#{string}\n\n" do
          ast = Myco::ToolSet::Parser.new('(eval)', 1, []).parse_string string
          ast = ast.body.array.last # Get rid of toplevel DeclareFile node
          ast.to_ruby.should eq expected if expected
        end
      end
    end
    
  end
end
