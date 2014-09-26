
class CodeTools::AST::ConstantAccess
  def to_ruby
    "::Myco.find_constant(#{@name.inspect})"
  end
end
