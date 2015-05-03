
module Myco
  # In Myco, try to always use Myco.add_method instead of Rubinius.add_method
  # to bypass all of the Ruby-specific logic therein.
  
  def self.add_method name, executable, mod
    mod.method_table.store(name, executable, :public)
    Rubinius::VM.reset_method_cache(mod, name)
  end
  
  # TODO: override Module#define_method in Component to use this?
  # TODO: override Module#thunk_method in Component to use this?
  # TODO: override Module#dynamic_method in Component to use this?
end
