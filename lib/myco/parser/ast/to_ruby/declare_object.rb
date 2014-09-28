
class CodeTools::AST::DeclareObject
  def to_ruby g
    g.add("(")
    g.add("__c__ = ::Myco::Component.new("); g.add(@types); g.add(", ::Myco.cscope.for_method_definition, __FILE__, __LINE__)")
    g.line("__c__.__last__ = __c__.component_eval { |__c__| "); g.add(@body); g.add("}")
    @create ? g.line("__c__.instance") : g.line("__c__")
    g.add(")")
  end
end
