
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
      inner_cscope.set_myco_file
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_cscope, item) }
      
      component.instance
      
    rescue Exception => e
      # Make the exception message more helpful without obfuscating the backtrace
      filename = cscope.respond_to?(:active_path) && cscope.active_path
      e.instance_variable_set(:@reason_message, "While evaluating #{filename}:\n#{e.message}")
      raise e
    end
    
    def self.evaluate_component(cscope, line, types, create, contents)
      supers = types.map { |type| evaluate(cscope, type) }
      component = ::Myco::Component.new(
        supers,
        cscope.for_method_definition,
        cscope.active_path.to_s,
        line
      )
      
      yield component if block_given?
      
      inner_cscope = ::Rubinius::ConstantScope.new(component, cscope)
      inner_cscope.set_myco_component
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_cscope, item) }
      
      create ? component.instance : component
      
    rescue Exception => e
      # Make the exception message more helpful without obfuscating the backtrace
      filename = cscope.respond_to?(:active_path) && cscope.active_path
      e.instance_variable_set(:@reason_message, "While evaluating component starting on line #{line}:\n#{e.message}")
      raise e
    end
    
    def self.evaluate_category(cscope, name, contents)
      category = cscope.for_method_definition.__category__(name)
      
      inner_cscope = ::Rubinius::ConstantScope.new(category, cscope)
      inner_cscope.set_myco_category
      contents.reduce(nil) { |_, item| evaluate(inner_cscope, item) }
    end
    
    def self.evaluate_extension(cscope, constant, contents)
      component = evaluate(cscope, constant)
      
      inner_cscope = ::Rubinius::ConstantScope.new(component, cscope)
      inner_cscope.set_myco_component
      contents.each { |item| evaluate(inner_cscope, item) }
      
      component
    end
    
    def self.evaluate_meme(cscope, name, decorations, body)
      inner_cscope = ::Rubinius::ConstantScope.new(cscope.module, cscope)
      body.block.instance_variable_set(:@constant_scope, inner_cscope)
      decorations = decorations.map { |deco| evaluate(cscope, deco) }
      inner_cscope.for_method_definition.declare_meme(name, decorations, &body)
    end
    
    def self.evaluate_decorator(cscope, name, arguments)
      [name, arguments] # TODO: try applying the decorator here
    end
    
    def self.evaluate_cmeme(cscope, constant, decorations, body)
      body.block.instance_variable_set(:@constant_scope, cscope)
      assign_constant(cscope, *constant, body.call)
    end
    
    def self.evaluate_const(cscope, line, toplevel, names)
      first_name, *rest_names = names
      const = if toplevel
        case first_name
        when :Myco;   ::Myco
        when :Ruby;   ::Object
        when :Rubinius; Rubinius
        else;         Rubinius::Type.const_get(::Myco, first_name.to_sym)
        end
      else
        ::Myco.find_constant(first_name, cscope)
      end
      
      rest_names.reduce(const) { |const, name| Rubinius::Type.const_get(const, name.to_sym) }
    end
    
    def self.evaluate_define(cscope, constant, component_data)
      evaluate(cscope, component_data) { |component|
        component.__name__ = constant.last.last.to_sym # TODO: use constant.names.last
        assign_constant(cscope, *constant, component)
      }
    end
    
    
    # TODO: deprecate/remove
    def self.evaluate_from_string(cscope, line, types, string)
      object = evaluate_component(cscope, line, types, true, [])
      object.from_string(string)
    end
    
    def self.assign_constant(cscope, node_type, line, toplevel, names, value)
      *names, last_name = names
      first_name = names.any? && names.shift
      
      const = if toplevel
        if first_name
          case first_name
          when :Myco;   ::Myco
          when :Ruby;   ::Object
          when :Rubinius; Rubinius
          else;         ::Myco.const_get(first_name)
          end
        else
          ::Myco
        end
      else
        if first_name
          ::Myco.find_constant(first_name, cscope)
        else
          cscope.for_method_definition
        end
      end
      
      parent = names.reduce(const) { |const, var| const.const_get(name) }
      parent.const_set(last_name, value)
      value
    end
    
  end
end
