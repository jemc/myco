
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
      if arguments && arguments.body.last.is_a?(BlockPass)
        block_arg = arguments.body.pop
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
          send = InvokeWithArguments.new @line, rcvr, @name, @arguments
          send
        end
      else
        rcvr = @receiver || Self.new(@line)
        send = InvokeWithArguments.new @line, rcvr, @name, @arguments
        if @block
          send.block = Iter.new @line, @block_params, @block
        elsif @block_arg
          send.block = @block_arg
        end
        send
      end
    end
  end
  
  class InvokeWithArguments < Node
    attr_accessor :line, :receiver, :name, :arguments, :privately
    attr_accessor :block
    
    def initialize line, receiver, name, arguments, privately=false
      @line      = line
      @receiver  = receiver
      @name      = name
      @arguments = arguments
      @privately = privately
      @block     = nil
    end
    
    def bytecode(g)
      @receiver.bytecode(g)
      
      if @arguments
        @arguments.bytecode(g)
        pos(g)
        
        # TODO: don't always send with splat
        # Right now the arguments are assembled into an ArrayAssembly
        # and sent as one object as a splat - with the number of arguments
        # before the splat being zero - but this is not always optimal.
        @block ? @block.bytecode(g) : g.push_nil
        g.send_with_splat @name, 0
      else
        pos(g)
        @block ? @block.bytecode(g) : g.push_nil
        g.send_with_block @name, 0
      end
    end
    
    def to_sexp
      arg_sexp = @arguments ? @arguments.to_sexp : [:arglist]
      arg_sexp[0] = :arglist
      arg_sexp.push(@block.to_sexp) if @block
      
      [:call, @receiver.to_sexp, @name, arg_sexp]
    end
  end
  
end
