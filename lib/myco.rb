
require_relative 'myco/version'
Myco.activate_required_gems

require_relative 'myco/code_loader'
require_relative 'myco/eval'
require_relative 'myco/misc'
require_relative 'myco/backtrace'
require_relative 'myco/bootstrap'

Myco.rescue do
  # TODO: be more clever here communicating the load path for bootstrapping
  Myco::CoreLoadPath = File.expand_path('myco', File.dirname(__FILE__))
  Myco.eval_file 'myco/bootstrap.my'
end

# Load the boot toolset from (possibly old) cached bytecode files
module Myco
  ToolSet = Rubinius::ToolSets.create :myco_boot do
    require "rubinius/melbourne"
    require "rubinius/compiler"
    
    require_relative 'myco/parser'
  end
end

# Load the runtime toolset from the latest code
module Myco
  ToolSet = Rubinius::ToolSets.create :myco do
    require "rubinius/melbourne"
    require "rubinius/compiler"
    
    require_relative 'myco/parser'
  end
end
