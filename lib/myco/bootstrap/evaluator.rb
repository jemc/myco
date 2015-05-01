
require_relative 'evaluator/context'

module Myco
  class Evaluator
    
    def self.evaluate(cscope, data, &block)
      type, *rest = data
      __send__(:"evaluate_#{type}", cscope, *rest, &block)
    end
    
    def self.evaluate_file(cscope, contents)
      component = ::Myco::Component.new(
        [::Myco::FileToplevel],
        cscope.for_method_definition,
        cscope.active_path.to_s,
        1
      )
      
      inner_cscope = ::Rubinius::ConstantScope.new(component, cscope)
      inner_cscope.myco_evctx.set_myco_file
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_cscope, item) }
      
      component.instance
      
    rescue Exception => e
      # Make the exception message more helpful without obfuscating the backtrace
      filename = cscope.respond_to?(:active_path) && cscope.active_path
      e.instance_variable_set(:@reason_message, "While evaluating #{filename}:\n#{e.message}")
      raise e
    end
    
    def self.evaluate_component(cscope, line, constant, types, contents)
      supers = types.map { |type| evaluate(cscope, type) }
      component = ::Myco::Component.new(
        supers,
        cscope.for_method_definition,
        cscope.active_path.to_s,
        line
      )
      
      component.__name__ = constant.last.last.to_sym # TODO: use constant.names.last
      assign_constant(cscope, *constant, component)
      
      inner_cscope = ::Rubinius::ConstantScope.new(component, cscope)
      inner_cscope.myco_evctx.set_myco_component
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_cscope, item) }
      
      component
      
    rescue Exception => e
      # Make the exception message more helpful without obfuscating the backtrace
      filename = cscope.respond_to?(:active_path) && cscope.active_path
      e.instance_variable_set(:@reason_message, "While evaluating component starting on line #{line}:\n#{e.message}")
      raise e
    end
    
    def self.evaluate_object(cscope, line, types, contents)
      supers = types.map { |type| evaluate(cscope, type) }
      component = ::Myco::Component.new(
        supers,
        cscope.for_method_definition,
        cscope.active_path.to_s,
        line
      )
      
      inner_cscope = ::Rubinius::ConstantScope.new(component, cscope)
      inner_cscope.myco_evctx.set_myco_component
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_cscope, item) }
      
      component.instance
      
    rescue Exception => e
      # Make the exception message more helpful without obfuscating the backtrace
      filename = cscope.respond_to?(:active_path) && cscope.active_path
      e.instance_variable_set(:@reason_message, "While evaluating object starting on line #{line}:\n#{e.message}")
      raise e
    end
    
    def self.evaluate_category(cscope, line, name, contents)
      category = cscope.for_method_definition.__category__(name)
      
      inner_cscope = ::Rubinius::ConstantScope.new(category, cscope)
      inner_cscope.myco_evctx.set_myco_category
      contents.reduce(nil) { |_, item| evaluate(inner_cscope, item) }
      
    rescue Exception => e
      # Make the exception message more helpful without obfuscating the backtrace
      filename = cscope.respond_to?(:active_path) && cscope.active_path
      e.instance_variable_set(:@reason_message, "While evaluating category starting on line #{line}:\n#{e.message}")
      raise e
    end
    
    def self.evaluate_extension(cscope, line, constant, types, contents)
      component = evaluate(cscope, constant)
      # TODO: inject the given types like includes/super_components
      
      inner_cscope = ::Rubinius::ConstantScope.new(component, cscope)
      inner_cscope.myco_evctx.set_myco_component
      contents.each { |item| evaluate(inner_cscope, item) }
      
      component
    rescue Exception => e
      # Make the exception message more helpful without obfuscating the backtrace
      filename = cscope.respond_to?(:active_path) && cscope.active_path
      e.instance_variable_set(:@reason_message, "While evaluating extension starting on line #{line}:\n#{e.message}")
      raise e
    end
    
    def self.evaluate_meme(cscope, name, decorations, body)
      # TODO: bring these two cases more semantically close together
      if name.is_a?(Symbol)
        inner_cscope = ::Rubinius::ConstantScope.new(cscope.module, cscope)
        body.block.instance_variable_set(:@constant_scope, inner_cscope)
        decorations = decorations.map { |deco| evaluate(cscope, deco) }
        inner_cscope.for_method_definition.declare_meme(name, decorations, &body)
      else
        constant = name
        body.block.instance_variable_set(:@constant_scope, cscope)
        assign_constant(cscope, *constant, body.call)
      end
    end
    
    def self.evaluate_decoration(cscope, name, arguments)
      [name, arguments] # TODO: try applying the decoration here
    end
    
    def self.evaluate_const(cscope, line, toplevel, names)
      first_name, *rest_names = names
      parent = search_constant(cscope, toplevel, first_name)
      rest_names.reduce(parent) { |parent, name| Rubinius::Type.const_get(parent, name.to_sym) }
    end
    
    
    # TODO: deprecate/remove
    def self.evaluate_from_string(cscope, line, types, string)
      object = evaluate_object(cscope, line, types, [])
      object.from_string(string)
    end
    
    def self.assign_constant(cscope, node_type, line, toplevel, names, value)
      *names, last_name = names
      first_name = names.any? && names.shift
      
      parent = search_constant(cscope, toplevel, first_name)
      parent = names.reduce(parent) { |parent, var| parent.const_get(name) }
      parent.const_set(last_name, value)
      value
    end
    
    def self.search_constant(cscope, toplevel, name=nil)
      if toplevel
        if name
          case name
          when :Myco;   ::Myco
          when :Ruby;   ::Object
          when :Rubinius; Rubinius
          else;         ::Myco.const_get(name)
          end
        else
          ::Myco
        end
      else
        if name
          ::Myco.find_constant(name, cscope)
        else
          cscope.for_method_definition
        end
      end
    end
    
  end
end
