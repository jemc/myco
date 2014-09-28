
class CodeTools::AST::DeclareCategory
  def to_ruby g
    g.add("__category__(#{@name.value.inspect})")
      g.add(".component_eval {"); g.add(@body); g.add("}")
  end
end
