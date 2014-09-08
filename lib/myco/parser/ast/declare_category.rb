
module CodeTools::AST
  
  module ProcessorMethods
    def process_category line, name
      DeclareCategory.new line, name
    end
  end
  
  class DeclareCategory < Node
    attr_accessor :name
    
    def initialize line, name
      @line = line
      @name = name
    end
    
    def to_sexp
      [:category, @name]
    end
    
    def bytecode g
      pos(g)
      
      ##
      # constant_scope.current_module = constant_scope.module
      # @category = self.__category__ @name
      # constant_scope.current_module = @category
      
      g.push_scope;
        g.push_scope; g.send :module, 0
      g.send :current_module=, 1
      
      g.push_self
        g.push_literal @name
      g.send :__category__, 1
      
      g.dup_top
      g.push_scope
      g.swap_stack
      g.send :current_module=, 1
    end
  end
  
end
