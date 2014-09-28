
require_relative 'myco_module_scope'

class CodeTools::AST::DeclareCategoryScope
  def to_ruby_scope_directive g
    g.line("__cscope__.set_myco_category")
  end
end

class CodeTools::AST::DeclareCategory
  def to_ruby g
    g.add("__category__(#{@name.value.inspect})")
      g.add(".module_eval {"); g.add(scope_implementation); g.add("}")
  end
end
