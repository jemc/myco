
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
      # self.__category__ @name
      #
      g.push_self
        g.push_literal @name
      g.send :__category__, 1
    end
  end
  
end
