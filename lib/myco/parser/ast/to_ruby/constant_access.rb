
class CodeTools::AST::ConstantAccess
  def to_ruby
    if @top_level
      "::#{@name}"
    else
      "::Myco.find_constant(#{@name.inspect})"
    end
  end
end
