
class CodeTools::AST::MycoModuleScope
  def to_ruby g
    g.with_nested_var_scope(self) {
      g.add(@body)
    }
  end
end
