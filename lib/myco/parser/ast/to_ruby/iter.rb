
class CodeTools::AST::Iter
  def to_ruby g
    g.with_nested_var_scope(self) {
      g.var_scope_declare_locals(@arguments.names)
      
      g.add(" "); g.add(@arguments); g.add(" "); g.add(@body)
    }
  end
end
