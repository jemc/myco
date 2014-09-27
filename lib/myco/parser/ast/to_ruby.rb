
module CodeTools::AST
  class ToRuby
    def initialize
      @lines = []
      @indents = [""]
    end
    
    def to_s
      @lines.join("\n")
    end
    
    def push_indent amount=2
      @indents.push(@indents.last + " "*2)
    end
    
    def pop_indent
      @indents.pop
    end
    
    def line string
      if string.is_a?(String)
        @lines.push(@indents.last + string)
      else
        @lines.push(@indents.last.dup)
        string.to_ruby(self)
      end
    end
    
    def add string
      if string.is_a?(String)
        (@lines.last || @lines[0]="").concat(string)
      else
        string.to_ruby(self)
      end
    end
  end
  
  class Node
    def to_ruby_code
      g = ToRuby.new
      to_ruby(g)
      g.to_s
    end
  end
end


require_relative "to_ruby/null_literal"
require_relative "to_ruby/string_literal"
require_relative "to_ruby/array_literal"
require_relative "to_ruby/constant_access"
require_relative "to_ruby/scoped_constant"
require_relative "to_ruby/toplevel_constant"
require_relative "to_ruby/declare_object"
require_relative "to_ruby/declare_string"
require_relative "to_ruby/send_with_arguments"
require_relative "to_ruby/arguments"
