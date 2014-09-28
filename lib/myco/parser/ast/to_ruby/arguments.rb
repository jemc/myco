
module CodeTools::AST
  class Arguments
    def to_ruby g
      list = @array.dup
      
      if @splat
        if list.last.is_a?(BlockPass)
          bp = list.pop
          list.push(@splat)
          list.push(bp)
        else
          list.push(@splat)
        end
      end
      
      if list.empty?
        g.add("()")
      else
        g.add("(")
        g.push_indent
          list[0...-1].each { |item| g.line(item); g.add(",") }
          list.last.tap     { |item| g.line(item) }
        g.pop_indent
        g.line(")")
      end
    end
  end
end
