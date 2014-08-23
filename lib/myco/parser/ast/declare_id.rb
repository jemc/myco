
module CodeTools::AST
  
  module ProcessorMethods
    def process_declid line, name
      DeclareId.new line, name
    end
  end
  
  class DeclareId < Define
    attr_accessor :name
    
    def initialize line, name
      @line = line
      @name = name.value
      
      @declfile = DeclareFile.current
      
      raise KeyError, "Cannot redefine id: #{@name} on line: #{@line}" \
        if @declfile.seen_ids.include? @name
      
      @declfile.seen_ids << @name
    end
    
    # TODO: fix/replace CodeTools::AST::AsciiGrapher to not infinitely recurse
    def instance_variables
      super - [:@declfile]
    end
    
    def to_sexp
      [:declid, @name]
    end
    
    def bytecode(g)
      pos(g)
      
      # component = scope.for_method_definition
      # component.__id__ = @name
      g.push_scope
      g.send :for_method_definition, 0
      g.dup_top
        g.push_literal @name
      g.send :__id__=, 1
    end
  end
  
end
