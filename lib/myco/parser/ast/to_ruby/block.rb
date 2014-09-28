
class CodeTools::AST::Block
  def to_ruby g
    if @array.empty?
      g.add("()")
    else
      g.add("(")
      g.push_indent
        @array.each { |item| g.line(item) }
      g.pop_indent
      g.line(")")
    end
  end
end
