
class CodeTools::AST::ScopedConstant
  def to_ruby
    "#{@parent.to_ruby}::#{@name}"
  end
end
