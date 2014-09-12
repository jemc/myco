
require_relative 'lib/myco'

Myco.rescue do
  program = Myco.eval_file("lib/myco/tools/mycompile.my")
  program.run("-A", "-e", "foo:bar")
end
