
require_relative 'lib/myco/toolset'
require_relative 'lib/myco/parser'
require_relative 'lib/myco/eval'
require_relative 'lib/myco/bootstrap'
require_relative 'lib/myco/backtrace'

Myco.eval_file 'lib/myco/bootstrap.my'

Myco.rescue do
  program = Myco.eval_file("lib/myco/tools/mycompile.my")
  program.run("-A", "-e", "foo:bar")
end
