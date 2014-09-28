
class CodeTools::AST::Arguments
  def to_ruby g
    list = @array.dup
    list.push(@splat) if @splat
    
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
