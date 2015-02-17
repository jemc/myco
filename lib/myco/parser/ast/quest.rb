
module CodeTools::AST
  
  module BuilderMethods
    def quest line, receiver, questable
      Quest.new line, receiver, questable
    end
  end
  
  class Quest < Node
    attr_accessor :receiver
    attr_accessor :questable
    
    def initialize line, receiver, questable
      @line      = line
      @receiver  = receiver
      @questable = questable
      
      @void_literal = VoidLiteral.new @line
      
      @questable.receiver = FakeReceiver.new @line
    end
    
    def bytecode g
      pos(g)
      
      ##
      # unless @receiver.respond_to?(@questable.name).false?
      #   execute_statement @questable
      # else
      #   return void
      # end
      
      else_label = g.new_label
      end_label  = g.new_label
      
      @receiver.bytecode g
      g.dup_top # dup the receiver to save it for later
        g.push_literal @questable.name
      g.send :respond_to?, 1
      g.send :false?, 0
      g.goto_if_true else_label
      
      # The duped receiver is still at the top of the stack,
      # and @questable.receiver has been set to an instance of FakeReceiver
      # to let the true receiver pass through instead.
      @questable.bytecode g
      g.goto end_label
      
      else_label.set!
      g.pop # pop the duped receiver - it won't be used after all
      g.push_cpath_top
      g.find_const :Myco
      g.find_const :Void
      
      end_label.set!
    end
    
    def to_sexp
      [:quest, @receiver.to_sexp, @questable.to_sexp]
    end
    
    class FakeReceiver < Node
      def initialize line
        @line = line
      end
      
      def bytecode g
        pos(g)
        # Do nothing here - this would normally be ill-advised,
        # because Nodes are expected to push an item onto the stack,
        # but here we are intentionally not doing so because
        # the real receiver should already at the top of the stack
      end
      
      def to_sexp
        [:qrcvr]
      end
    end
  end
  
end
