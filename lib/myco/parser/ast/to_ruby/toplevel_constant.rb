
class CodeTools::AST::ToplevelConstant
  def to_ruby
    "::#{@name}"
  end
end
