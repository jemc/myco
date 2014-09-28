
class CodeTools::AST::Send
  def to_ruby g
    unless @vcall_style
      g.add(@receiver); g.add(".")
    end
    g.add(@name.to_s)
  end
end
