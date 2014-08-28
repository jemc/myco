
module CodeTools::AST
  
  module ProcessorMethods
    def process_invoke line, receiver, name, arguments, *rest
      Invoke.new line, receiver, name, arguments, *rest
    end
  end
  
  class Invoke < Node
    attr_accessor :receiver, :name, :arguments, :block_params, :block
    
    def initialize line, receiver, name, arguments, block_params=nil, block=nil
      block_arg = nil
      if arguments.is_a? BlockPass
        block_arg = arguments
        arguments = block_arg.arguments
        block_arg.arguments = nil
      end
      
      @line         = line
      @receiver     = receiver
      @name         = name
      @arguments    = arguments
      @block_params = block_params
      @block        = block
      @block_arg    = block_arg
    end
    
    def bytecode g
      pos(g)
      
      implementation.bytecode(g)
    end
    
    def to_sexp
      implementation.to_sexp
    end
    
    def implementation
      if @block.nil? && @block_arg.nil?
        if @arguments.nil?
          if @receiver.nil?
            LocalVariableAccessAmbiguous.new @line, @name
          else
            Send.new @line, @receiver, @name
          end
        else
          rcvr = @receiver || Self.new(@line)
          send = SendWithArguments.new @line, rcvr, @name, @arguments
          send
        end
      else
        rcvr = @receiver || Self.new(@line)
        send = SendWithArguments.new @line, rcvr, @name, @arguments
        if @block
          send.block = Iter.new @line, @block_params, @block
        elsif @block_arg
          send.block = @block_arg
        end
        send
      end
    end
  end
  
end
