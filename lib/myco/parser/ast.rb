
module CodeTools::AST
  module BuilderMethods; end
end

Myco.eval_file 'ast/MycoModuleScope.my'

Myco.eval_file 'ast/ConstantAccess.my'
Myco.eval_file 'ast/ConstantDefine.my'
Myco.eval_file 'ast/ConstantReopen.my'
Myco.eval_file 'ast/DeclareCategory.my'
Myco.eval_file 'ast/DeclareDecorator.my'
Myco.eval_file 'ast/DeclareFile.my'
Myco.eval_file 'ast/DeclareMeme.my'
Myco.eval_file 'ast/DeclareObject.my'
Myco.eval_file 'ast/DeclareString.my'

Myco.eval_file 'ast/Invoke.my'
Myco.eval_file 'ast/LocalVariableAccessAmbiguous.my'
Myco.eval_file 'ast/InvokeMethod.my'

require_relative "ast/array_assembly"
require_relative "ast/argument_assembly"
require_relative "ast/quest"
require_relative "ast/branch_operator"

require_relative "ast/misc"

Myco.eval_file 'ast/ToRuby.my'
