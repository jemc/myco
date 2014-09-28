
require_relative 'myco_module_scope'

class CodeTools::AST::DeclareObjectScope
  def to_ruby_scope_directive g
    g.line("__cscope__.set_myco_component")
  end
end

class CodeTools::AST::DeclareObject
  def to_ruby g
    g.add("(")
    g.add("__c__ = ::Myco::Component.new("); g.add(@types); g.add(", self, __FILE__, __LINE__)")
    g.line("__c__.__last__ = __c__.module_eval {"); g.add(scope_implementation); g.add("}")
    @create ? g.line("__c__.instance") : g.line("__c__")
    g.add(")")
  end
end
