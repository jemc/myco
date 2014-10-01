
module CodeTools::AST
  class InvokeWithArguments
    def to_ruby g
      body_block = nil
      
      args = @arguments ? @arguments.body.dup : []
      
      args.unshift(SymbolLiteral.new(@line, @name))
      
      if @block.is_a?(BlockPass)
        args.push(@block)
      else
        body_block = @block
      end
      
      g.add(@receiver); g.add(".__send__");
      
      if args.empty?
        g.add("()")
      else
        g.add("(")
        g.push_indent
          args[0...-1].each { |item| g.line(item); g.add(",") }
          args.last.tap     { |item| g.line(item) }
        g.pop_indent
        g.line(")")
      end
      
      if body_block
        g.add(" {"); g.add(@block); g.add("}")
      end
    end
  end
end
