
module CodeTools::AST
  class InvokeMethod
    def to_ruby g
      list = @arguments ? @arguments.body.dup : []
      list.push(@arguments.block) if @arguments.block.is_a?(BlockPass)
      
      list.unshift(SymbolLiteral.new(@line, @name))
      
      g.add(@receiver); g.add(".__send__")
      
      if list.empty?
        g.add("()")
      elsif list.size == 1
        g.add("("); g.add(list.first); g.add(")")
      else
        g.add("(")
        g.push_indent
          list[0...-1].each { |item| g.line(item); g.add(",") }
          list.last.tap     { |item| g.line(item) }
        g.pop_indent
        g.line(")")
      end
      
      if @arguments.block.is_a?(Iter)
        (g.add(" {"); g.add(@arguments.block); g.add("}"))
      end
    end
  end
end
