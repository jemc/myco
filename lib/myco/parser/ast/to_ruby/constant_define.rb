
class CodeTools::AST::ConstantDefine
  def to_ruby g
    g.add("(")
    g.add("__d__ = "); g.add(implementation)
    g.line("__d__.__name__="); g.add(@name.name.inspect)
    g.line("__d__")
    g.add(")")
  end
end
