
module CodeTools::AST
  module BuilderMethods; end
end

Myco.eval_file 'ast/ConstantAccess.my'
Myco.eval_file 'ast/ConstantDefine.my'
require_relative "ast/constant_reopen"
require_relative "ast/declare_category"
require_relative "ast/declare_decorator"
require_relative "ast/declare_file"
require_relative "ast/declare_meme"
require_relative "ast/declare_object"
require_relative "ast/declare_string"
require_relative "ast/invoke"
require_relative "ast/local_variable_access_ambiguous"
require_relative "ast/invoke_method"
require_relative "ast/array_assembly"
require_relative "ast/argument_assembly"
require_relative "ast/quest"
require_relative "ast/branch_operator"

require_relative "ast/misc"

Myco.eval_file 'ast/ToRuby.my'
