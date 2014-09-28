
class CodeTools::AST::ConstantAccess
  def to_ruby g
    g.add("::Myco.find_constant(#{@name.inspect})")
  end
  
  def to_ruby_assign g, value
    g.add("::Myco.cscope.for_method_definition.const_set(#{@name.inspect}, "); g.add(value); g.add(")")
  end
end
