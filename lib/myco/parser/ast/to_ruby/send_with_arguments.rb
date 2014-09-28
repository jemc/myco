
module CodeTools::AST
  class SendWithArguments
    def to_ruby g
      body_block = nil
      
      args = @arguments.dup
      
      args.array.unshift(SymbolLiteral.new(@line, @name))
      
      if @block.is_a?(BlockPass)
        args.array.push(@block)
      else
        body_block = @block
      end
      
      g.add(@receiver); g.add(".__send__"); g.add(args)
      
      if body_block
        g.add(" {"); g.add(@block); g.add("}")
      end
    end
  end
end
