
class CodeTools::AST::SplatValue
  def to_ruby g
    if @value.is_a?(self.class)
      @value.to_ruby(g)
    else
      g.add("*(")
      @value.to_ruby(g)
      g.add(")")
    end
  end
end
