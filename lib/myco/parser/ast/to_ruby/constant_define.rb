
class CodeTools::AST::ConstantDefine
  def to_ruby g
    g.add(implementation)
    g.add(".tap { |__c__| __c__.__name__ = ")
      g.add(@name.name.inspect)
    g.add(" }")
  end
end
