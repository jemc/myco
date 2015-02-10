
class CodeTools::AST::BranchOperator
  def to_ruby g
    g.add('::Myco.branch_op(');
      g.add(":\"#{@type}\""); g.add(', ');
      g.add(@left); g.add(') {');
      g.add(@right); g.add('}')
  end
end
