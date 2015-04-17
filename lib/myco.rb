
require_relative 'myco/version'
Myco.activate_required_gems

Myco::SingletonClass = Myco.singleton_class

require_relative 'myco/code_loader'
require_relative 'myco/eval'
require_relative 'myco/misc'
require_relative 'myco/backtrace'
require_relative 'myco/bootstrap'


# Detect whether a second pass is necessary (when no bytecode is available)
# TODO: recursively check mtime for all rbc files as well,
#   to be sure that core implementation files don't need to be recompiled.
if File.file?(File.expand_path('myco/bootstrap.my.rbc', File.dirname(__FILE__)))
  stages = [:myco]
else
  stages = [:myco_boot, :myco]
end

# Run the stages, ultimately creating the runtime toolset
# First pass:  Load the boot toolset (when only ruby source code is available)
# Second pass: Load the runtime toolset using the boot toolset to parse it
stages.each do |toolset_name|
  Myco::ToolSet = Rubinius::ToolSets.create toolset_name do
    
    Myco.rescue do
      # TODO: be more clever here communicating the load path for bootstrapping
      Myco::CoreLoadPath = File.expand_path('myco', File.dirname(__FILE__))
      Myco.eval_file 'myco/bootstrap.my'
    end
    
    require "rubinius/compiler"
    
    require_relative 'myco/code_tools'
  end
end
