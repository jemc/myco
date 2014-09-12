
require_relative 'myco/toolset'
require_relative 'myco/parser'
require_relative 'myco/eval'
require_relative 'myco/backtrace'
require_relative 'myco/bootstrap'

Myco.rescue do
  Myco.eval_file 'myco/bootstrap.my'
end
