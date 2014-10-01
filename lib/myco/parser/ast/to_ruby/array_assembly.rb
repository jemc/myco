
class CodeTools::AST::ArrayAssembly
  def to_ruby g
    if @body.empty?
      g.add("[]")
    else
      g.add("[")
      g.push_indent
        @body[0...-1].each { |item| g.line(item); g.add(",") }
        @body.last.tap     { |item| g.line(item) }
      g.pop_indent
      g.line("]")
    end
  end
end
