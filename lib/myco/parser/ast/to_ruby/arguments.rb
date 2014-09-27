
class CodeTools::AST::Arguments
  def to_ruby g
    g.add("(")
    g.push_indent
      list = @array.dup
      list.push(@splat) if @splat
      list[0...-1].each { |item| g.line(item); g.add(",") }
      list.last.tap     { |item| g.line(item) }
    g.pop_indent
    g.line(")")
  end
end
