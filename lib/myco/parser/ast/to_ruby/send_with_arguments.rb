
class CodeTools::AST::SendWithArguments
  def to_ruby g
    g.add(@receiver); g.add(".#{@name}"); g.add(@arguments)
    
    if @block
      g.add(" {"); g.add(@block); g.add("}")
    end
  end
end
