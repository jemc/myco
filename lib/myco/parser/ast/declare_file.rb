
module CodeTools::AST
  
  module ProcessorMethods
    def process_declfile line, body
      DeclareFile.new line, body
    end
  end
  
  class DeclareFile < Node
    attr_accessor :body
    
    # Use minimal inspect to avoid huge inspect output for inner AST nodes
    # that store a reference to a DeclareFile in an instance variable. 
    def inspect
      to_s
    end
    
    def initialize line, body
      @line = line
      @body = body
      
      @seen_ids = []
      DeclareFile.current = self
    end
    
    def to_sexp
      [:declfile, @body.to_sexp]
    end
    
    def implementation
      type = ConstantAccess.new @line, :FileToplevel
      types = ArrayLiteral.new @line, [type]
      DeclareObject.new @line, types, @body
    end
    
    def bytecode g
      pos(g)
      
      implementation.bytecode g
    end
    
    attr_reader :seen_ids
    class << self; attr_accessor :current; end
  end
  
end
