
module CodeTools::AST
  
  module BuilderMethods
    def branch_op loc, type, left, right
      BranchOperator.new loc.line, type, left, right
    end
  end
  
  class BranchOperator < Node
    attr_accessor :type
    attr_accessor :left
    attr_accessor :right
    
    def initialize line, type, left, right
      @line  = line
      @type  = type
      @left  = left
      @right = right
    end
    
    def bytecode g
      pos(g)
      
      done_label = g.new_label
      right_label = g.new_label
      can_push_void = false
      
      @left.bytecode(g)
      
      case type
      when :"&&"
        g.dup_top
        g.send :false?, 0
        g.goto_if_true done_label
        g.pop
      when :"||"
        g.dup_top
        g.send :false?, 0
        g.goto_if_false done_label
        g.pop
      when :"??"
        g.dup_top
        g.send :void?, 0
        g.goto_if_false done_label
        g.pop
      when :"&?"
        g.send :false?, 0
        g.goto_if_false right_label
        otherwise_push_void = true
      when :"|?"
        g.send :false?, 0
        g.goto_if_true right_label
        otherwise_push_void = true
      end
      
      if otherwise_push_void
        g.push_void
        g.goto done_label
        
        right_label.set!
      end
      
      @right.bytecode(g)
      done_label.set!
    end
    
    def to_sexp
      [:branch_op, @type, @left.to_sexp, @right.to_sexp]
    end
  end
  
end
