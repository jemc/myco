
module CodeTools::AST
  
  module ProcessorMethods
    def process_category line, name, body
      DeclareCategory.new line, name, body
    end
  end
  
  class DeclareCategoryScope < ModuleScope
    def initialize(line, body)
      @line = line
      @name = :DeclareCategoryScope # TODO: remove/fix
      @body = body
    end
    
    def bytecode(g)
      pos(g)
      
      attach_and_call g, :__category_init__, true
    end
  end
  
  class DeclareCategory < Node
    attr_accessor :name, :body
    
    def initialize line, name, body
      @line = line
      @name = name
      @body = body
    end
    
    def to_sexp
      [:category, @name.value, @body.to_sexp]
    end
    
    def bytecode g
      pos(g)
      
      scope = DeclareCategoryScope.new @line, @body
      
      ##
      # category = self.__category__ @name
      g.push_self
        g.push_literal @name.value
      g.send :__category__, 1
      
      scope.bytecode g
    end
  end
  
end
