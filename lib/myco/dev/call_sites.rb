
module Myco
  module DEV
    class CallSites
      class << self
        
        def report(*modules)
          list = []
          if modules.empty?
            ObjectSpace.each_object(Module) { |mod| analyze_module(mod, list) }
          else
            modules.each { |mod| analyze_module(mod, list) }
          end
          list.uniq.sort
        end
        
        def report!(*args, count: 2000)
          list = report(*args)
          list = list[-count..-1] if list.size > count
          list.each { |item| p item }
        end
        
        def analyze_module(mod, list)
          mod.method_table.each_entry do |name, executable, _|
            if executable.respond_to?(:call_sites)
              executable.call_sites.each do |cache|
                called = "#{cache.stored_module}##{cache.method.name}" rescue "#{cache.name}"
                caller = "#{mod}##{name}"
                location = "#{executable.active_path}:#{executable.line_from_ip(0)}"
                
                list.push [cache.hits, "#{called} in #{caller} near #{location}"]
              end
            end
          end
        end
      end
    end
  end
end
