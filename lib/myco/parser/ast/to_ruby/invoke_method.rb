
module CodeTools::AST
  class InvokeMethod
    def to_ruby g
      list = @arguments ? @arguments.body.dup : []
      list.push(@arguments.block) if @arguments.block.is_a?(BlockPass)
      
      g.add(@receiver)
      
      if g.easy_ident?(@name)
        g.add(".#{@name}")
      else
        g.add(".__send__")
        list.unshift(SymbolLiteral.new(@line, @name))
      end
      
      if list.empty?
        g.add("")
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
