
class CodeTools::AST::ConstantAccess
  def to_ruby g
    g.add("::Myco.find_constant(#{@name.inspect}, __cscope__)")
  end
  
  def to_ruby_assign g, value
    g.add("__cscope__.module.const_set(#{@name.inspect}, "); g.add(value); g.add(")")
  end
end
