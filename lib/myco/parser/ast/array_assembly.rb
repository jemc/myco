
module CodeTools::AST
  
  module BuilderMethods
    def arrass line, body
      ArrayAssembly.new line, body
    end
  end
  
  class ArrayAssembly < Node
    attr_accessor :body
    
    def initialize(line, body)
      @line = line
      @body = body
    end
    
    def bytecode(g)
      pos(g)
      
      if @body.empty?
        g.make_array(0)
        return
      end
      
      # Group the @body into chunks of splats and non-splats
      chunked = @body.chunk { |item| item.is_a?(SplatValue) }
      
      # Each SplatValue outputs the bytecode of a single array
      # Non-SplatValues are grouped to output the bytecode of
      # a single array for each contiguous group.  Along the way, the
      # arrays are concatenated to form one final array on the stack.
      first_bytecode = true
      chunked.each do |is_splat_group, group|
        if is_splat_group
          group.each { |item|
            item.bytecode(g)
            g.send(:concat, 1) unless first_bytecode
            first_bytecode = false
          }
        else
          group.each { |item|
            item.bytecode(g)
          }
          g.make_array(group.size)
          g.send(:concat, 1) unless first_bytecode
          first_bytecode = false
        end
      end
    end
    
    def to_sexp
      [:array] + @body.map(&:to_sexp)
    end
  end
   
end
