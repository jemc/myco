
require_relative 'myco/version'
Myco.activate_required_gems

require_relative 'myco/code_loader'
require_relative 'myco/eval'
require_relative 'myco/misc'
require_relative 'myco/backtrace'
require_relative 'myco/bootstrap'

# First pass:  Load the boot toolset
# Second pass: Load the runtime toolset using the boot toolset to parse it
# TODO: detect whether a second pass is really necessary (ie, booting from ruby)
[:myco_boot, :myco].each do
  Myco::ToolSet = Rubinius::ToolSets.create :myco_boot do
    
    Myco.rescue do
      # TODO: be more clever here communicating the load path for bootstrapping
      Myco::CoreLoadPath = File.expand_path('myco', File.dirname(__FILE__))
      Myco.eval_file 'myco/bootstrap.my'
    end
    
    require "rubinius/melbourne"
    require "rubinius/compiler"
    
    require_relative 'myco/parser'
  end
end
