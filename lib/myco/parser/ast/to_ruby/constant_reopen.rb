
class CodeTools::AST::ConstantReopen
  def to_ruby g
    g.add(@name); g.add(".module_eval {"); g.add(@body); g.add("}")
  end
end
