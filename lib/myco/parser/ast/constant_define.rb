
module CodeTools::AST
  
  module BuilderMethods
    def cdefn line, name, object
      ConstantDefine.new line, name, object
    end
  end
  
  class ConstantDefine < Node
    attr_accessor :name, :object
    
    def initialize line, name, object
      @line   = line
      @name   = name
      @object = object
      @object.create = false
    end
    
    def to_sexp
      [:cdefn, @name.name, @object.to_sexp]
    end
    
    def implementation
      ConstantAssignment.new @line, @name, @object
    end
    
    def bytecode g
      pos(g)
      
      implementation.bytecode g
      
      g.dup_top
        g.push_literal @name.name
      g.send :__name__=, 1
      g.pop
    end
  end
  
end
