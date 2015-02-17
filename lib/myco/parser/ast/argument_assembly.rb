
module CodeTools::AST
  
  module BuilderMethods
    def argass line, body
      ArgumentAssembly.new line, body
    end
  end
  
  class ArgumentAssembly < Node
    attr_accessor :body, :block
    
    def initialize(line, body, block=nil)
      @line = line
      @body = body
      
      # TODO: error for multiple block arguments
      @block = body.pop if body.last.is_a?(BlockPass)
    end
    
    # All items before the first SplatValue
    def pre_group
      @body.take_while { |item| !item.is_a?(SplatValue) }
    end
    
    # All items after and including the first SplatValue
    def post_group
      @body.drop_while { |item| !item.is_a?(SplatValue) }
    end
    
    # Symbol of bytecode operation to use for send
    def send_op
      if @body.detect { |item| item.is_a?(SplatValue) }
        :send_with_splat
      elsif @block
        :send_with_block
      else
        :send
      end
    end
    
    # Number of arguments to use for send operation
    def send_count
      pre_group.size
    end
    
    def splat_bytecode(g)
      ArrayAssembly.new(@line, post_group).bytecode(g)
    end
    
    def block_bytecode(g)
      @block ? @block.bytecode(g) : g.push_nil
    end
    
    def bytecode(g)
      pos(g)
      
      pre_group.each { |item| item.bytecode(g) }
      
      case send_op
      when :send_with_splat
        splat_bytecode(g)
        block_bytecode(g)
      when :send_with_block
        block_bytecode(g)
      end
    end
    
    def to_sexp
      sexp = [:arglist] + @body.map(&:to_sexp)
      sexp.push(@block.to_sexp) if @block
      sexp
    end
  end
   
end
