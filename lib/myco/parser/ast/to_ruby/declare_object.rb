
class CodeTools::AST::DeclareObject
  def to_ruby g
    g.add("::Myco::Component.new("); g.add(@types); g.add(", ::Myco.cscope.for_method_definition, __FILE__, __LINE__)")
    g.line(".tap { |__c__| __c__.__last__ = __c__.component_eval {"); g.add(scope_implementation); g.add("}}")
    g.add(".instance") if @create
  end
end
