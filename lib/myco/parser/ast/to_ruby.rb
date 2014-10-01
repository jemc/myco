
module CodeTools::AST
  class ToRuby
    def initialize
      @lines = []
      @indents = [""]
      
      @var_scopes = []
    end
    
    # The currently held string of generated ruby code
    def to_s
      @lines.join("\n")
    end
    
    # Start a new line, optionally adding a string
    # or an object that responds to :to_ruby
    def line string=""
      if string.is_a?(String)
        @lines.push(@indents.last + string)
      else
        line
        string.to_ruby(self)
      end
    end
    
    # Add to the current line a string
    # or an object that responds to :to_ruby
    def add string
      if string.is_a?(String)
        (@lines.last || @lines[0]="").concat(string)
      else
        string.to_ruby(self)
      end
    end
    
    ##
    # Stack of indent levels (as strings to be prefixed)
    #
    def push_indent amount=2
      @indents.push(@indents.last + " "*2)
    end
    
    def pop_indent
      @indents.pop
    end
    
    ##
    # Stack of every AST node in hierarchy that can hold local variables
    #
    def var_scope
      @var_scopes.last
    end
    
    def with_nested_var_scope node
      @var_scopes.push(node)
      yield
    ensure
      @var_scopes.pop
    end
    
    def var_scope_has_local? name
      @var_scopes.reverse.each { |scope|
        return true if scope.variables.has_key?(name)
      }
      return false
    end
    
    def var_scope_declare_local name
      var_scope.variables[name] = true
    end
    
    def var_scope_declare_locals names
      names.each { |name| var_scope_declare_local(name) }
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


require_relative "to_ruby/self"
require_relative "to_ruby/null_literal"
require_relative "to_ruby/void_literal"
require_relative "to_ruby/true_literal"
require_relative "to_ruby/false_literal"
require_relative "to_ruby/string_literal"
require_relative "to_ruby/symbol_literal"
require_relative "to_ruby/array_literal"
require_relative "to_ruby/hash_literal"
require_relative "to_ruby/dynamic_string"
require_relative "to_ruby/dynamic_symbol"
require_relative "to_ruby/scoped_constant"
require_relative "to_ruby/toplevel_constant"
require_relative "to_ruby/constant_access"
require_relative "to_ruby/constant_assignment"
require_relative "to_ruby/constant_define"
require_relative "to_ruby/constant_reopen"
require_relative "to_ruby/myco_module_scope"
require_relative "to_ruby/declare_file"
require_relative "to_ruby/declare_object"
require_relative "to_ruby/declare_string"
require_relative "to_ruby/declare_category"
require_relative "to_ruby/declare_meme"
require_relative "to_ruby/declare_decorator"
require_relative "to_ruby/parameters"
require_relative "to_ruby/block"
require_relative "to_ruby/invoke"
require_relative "to_ruby/invoke_with_arguments"
require_relative "to_ruby/local_variable_assignment"
require_relative "to_ruby/local_variable_access_ambiguous"
require_relative "to_ruby/send"
require_relative "to_ruby/arguments"
require_relative "to_ruby/splat_value"
require_relative "to_ruby/block_pass"
require_relative "to_ruby/iter"
require_relative "to_ruby/and"
require_relative "to_ruby/or"
require_relative "to_ruby/quest"
require_relative "to_ruby/return"
require_relative "to_ruby/array_assembly"
