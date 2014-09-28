
class CodeTools::AST::HashLiteral
  def to_ruby g
    list = @array.each_slice(2).to_a
    if list.empty?
      g.add("{}")
    else
      g.add("{")
      g.push_indent
        list[0...-1].each { |key, value| g.line(key); g.add(" => "); g.add(value); g.add(",") }
        list.last.tap     { |key, value| g.line(key); g.add(" => "); g.add(value) }
      g.pop_indent
      g.line("}")
    end
  end
end
