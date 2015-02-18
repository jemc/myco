
module CodeTools::AST
  
  module BuilderMethods
    def invoke loc, receiver, name, arguments, *rest
      Invoke.new loc.line, receiver, name, arguments, *rest
    end
  end
  
  class Invoke < Node
    attr_accessor :receiver, :name, :arguments
    
    def initialize line, receiver, name, arguments, block_params=nil, block=nil
      @line      = line
      @receiver  = receiver
      @name      = name
      @arguments = arguments
      
      if block
        # TODO: error if passing both block argument and block literal
        # Currently, this fails silently and ignores the block argument
        @arguments ||= ArgumentAssembly.new(line, [])
        @arguments.block = Iter.new(line, block_params, block)
      end
    end
    
    def bytecode g
      pos(g)
      
      implementation.bytecode(g)
    end
    
    def to_sexp
      implementation.to_sexp
    end
    
    def implementation
      if @receiver.nil? && @arguments.nil?
        LocalVariableAccessAmbiguous.new(@line, @name)
      else
        rcvr = @receiver || Self.new(@line)
        args = @arguments || ArgumentAssembly.new(line, [])
        InvokeMethod.new @line, rcvr, @name, args
      end
    end
  end
  
end
