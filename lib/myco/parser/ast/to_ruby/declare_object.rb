
class CodeTools::AST::DeclareObject
  def to_ruby g
    g.add("(")
    g.add("__c__ = ::Myco::Component.new("); g.add(@types); g.add(", self, __FILE__, __LINE__)")
    g.line("__c__.__last__ = __c__.module_eval {"); g.add(@body); g.add("}")
    g.line("__c__.instance") if @create
    g.add(")")
  end
end
