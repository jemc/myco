
module CodeTools::AST
  module BuilderMethods; end
end

Myco.eval_file 'ast/StringLiteral.my'
Myco.eval_file 'ast/SymbolLiteral.my'

Myco.eval_file 'ast/SplatValue.my'
Myco.eval_file 'ast/ArrayAssembly.my'
Myco.eval_file 'ast/KeywordAssembly.my'
Myco.eval_file 'ast/ArgumentAssembly.my'

Myco.eval_file 'ast/MycoModuleScope.my'

Myco.eval_file 'ast/ConstantAccess.my'
Myco.eval_file 'ast/ConstantAccessScoped.my'
Myco.eval_file 'ast/ConstantAccessToplevel.my'
Myco.eval_file 'ast/ConstantAssignment.my'
Myco.eval_file 'ast/ConstantDefine.my'
Myco.eval_file 'ast/ConstantReopen.my'
Myco.eval_file 'ast/DeclareCategory.my'
Myco.eval_file 'ast/DeclareDecorator.my'
Myco.eval_file 'ast/DeclareFile.my'
Myco.eval_file 'ast/DeclareMeme.my'
Myco.eval_file 'ast/DeclareObject.my'
Myco.eval_file 'ast/DeclareString.my'

Myco.eval_file 'ast/Invoke.my'
Myco.eval_file 'ast/InvokeMethod.my'
Myco.eval_file 'ast/LocalVariableAccessAmbiguous.my'
Myco.eval_file 'ast/LocalVariableAssignment.my'

Myco.eval_file 'ast/Quest.my'
Myco.eval_file 'ast/BranchOperator.my'

# TODO: refactor and break out misc
Myco.eval_file "ast/misc.my"

Myco.eval_file 'ast/ToRuby.my'
