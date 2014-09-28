
class CodeTools::AST::Send
  def to_ruby g
    g.add(@name.to_s)
  end
end
