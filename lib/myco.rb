
require_relative 'myco/version'
Myco.activate_required_gems

require_relative 'myco/toolset'
require_relative 'myco/parser'
require_relative 'myco/eval'
require_relative 'myco/misc'
require_relative 'myco/backtrace'
require_relative 'myco/bootstrap'

Myco.rescue do
  # TODO: be more clever here communicating the load path for bootstrapping
  Myco::CoreLoadPath = File.expand_path('myco', File.dirname(__FILE__))
  Myco.eval_file 'myco/bootstrap.my'
end
