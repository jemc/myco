
module CodeTools::AST
  
  class InvokeMethod < Node
    attr_accessor :line, :receiver, :name, :arguments
    
    def initialize line, receiver, name, arguments
      @line      = line
      @receiver  = receiver
      @name      = name
      @arguments = arguments
    end
    
    def bytecode(g)
      @receiver.bytecode(g)
      @arguments.bytecode(g)
      
      pos(g)
      
      g.__send__(@arguments.send_op, @name, @arguments.send_count)
    end
    
    def to_sexp
      [:call, @receiver.to_sexp, @name, @arguments.to_sexp]
    end
  end
  
end
