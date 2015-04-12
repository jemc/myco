
module Myco
  class Evaluator
    
    def self.evaluate(cscope, data)
      type, *rest = data
      __send__(:"evaluate_#{type}", cscope, *rest)
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
    end
    
    def self.evaluate_component(cscope, line, types, create, contents)
      supers = types.map { |data| resolve_constant(cscope, *data) }
      component = ::Myco::Component.new(
        supers,
        cscope.for_method_definition,
        cscope.active_path.to_s,
        line
      )
      
      inner_cscope = ::Rubinius::ConstantScope.new(component, cscope)
      inner_cscope.set_myco_component
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_cscope, item) }
      
      create ? component.instance : component
    end
    
    def self.evaluate_category(cscope, name, contents)
      category = cscope.for_method_definition.__category__(name)
      
      inner_cscope = ::Rubinius::ConstantScope.new(category, cscope)
      inner_cscope.set_myco_category
      contents.reduce(nil) { |_, item| evaluate(inner_cscope, item) }
    end
    
    def self.evaluate_extension(cscope, constant, contents)
      component = resolve_constant(cscope, *constant)
      
      inner_cscope = ::Rubinius::ConstantScope.new(component, cscope)
      inner_cscope.set_myco_component
      contents.each { |item| evaluate(inner_cscope, item) }
      
      component
    end
    
    def self.evaluate_meme(cscope, name, decorations, body)
      inner_cscope = ::Rubinius::ConstantScope.new(cscope.module, cscope)
      body.block.instance_variable_set(:@constant_scope, inner_cscope)
      inner_cscope.for_method_definition.declare_meme(name, decorations, &body)
    end
    
    def self.evaluate_cmeme(cscope, constant, decorations, body)
      body.block.instance_variable_set(:@constant_scope, cscope)
      assign_constant(cscope, *constant, body.call)
    end
    
    def self.evaluate_define(cscope, constant, component)
      component = evaluate(cscope, component)
      component.__name__ = constant_name(cscope, *constant)
      assign_constant(cscope, *constant, component)
    end
    
    
    # TODO: deprecate/remove
    def self.evaluate_from_string(cscope, line, types, string)
      object = evaluate_component(cscope, line, types, true, [])
      object.from_string(string)
    end
    
    def self.resolve_constant(cscope, node_type, line, toplevel, names)
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
    
    def self.constant_name(cscope, node_type, line, toplevel, names)
      names.last.to_sym
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
      
      names.reduce(const) { |const, var| const.const_get(name) }
           .const_set(last_name, value)
    end
    
  end
end
