
module CodeTools::AST
  
  module ProcessorMethods
    def process_arrass line, body
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
      else
        @body.each_with_index do |item, idx|
          item.bytecode(g)
          g.make_array(1) unless item.is_a?(SplatValue)
          g.send(:+, 1) unless idx==0
        end
      end
    end
    
    def to_sexp
      @body.inject([:array]) { |sexp, item| sexp.push(item.to_sexp) }
    end
  end
   
end
