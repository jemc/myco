
class CodeTools::AST::Block
  def to_ruby g
    g.add("(")
    g.push_indent
      @array.each { |item| g.line(item) }
    g.pop_indent
    g.line(")")
  end
end
