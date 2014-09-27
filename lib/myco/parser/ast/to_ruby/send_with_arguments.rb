
class CodeTools::AST::SendWithArguments
  def to_ruby g
    g.add(@receiver); g.add(".#{@name}"); g.add(@arguments)
    g.add(@block) if @block
  end
end
