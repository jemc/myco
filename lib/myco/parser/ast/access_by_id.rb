
module CodeTools::AST
  
  class AccessById < Define
    attr_accessor :name
    
    def initialize line, name
      @line = line
      @name = name
    end
    
    def to_sexp
      [:declid, @name]
    end
    
    def bytecode(g)
      pos(g)
      
      # component = scope.for_method_definition
      # component.get_by_id @name
      g.push_scope; g.send :for_method_definition, 0
        g.push_literal @name
      g.send :get_by_id, 1
    end
  end
  
end
