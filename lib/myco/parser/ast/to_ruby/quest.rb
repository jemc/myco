
class CodeTools::AST::Quest
  def to_ruby g
    associated_questable = @questable.dup
    associated_questable.receiver = @receiver
    
    g.add("(")
      g.add(@receiver); g.add(".respond_to?(#{@questable.name.inspect}).false?")
      g.add(" ? ::Myco::Void : ")
      g.add(associated_questable)
    g.add(")")
  end
end
