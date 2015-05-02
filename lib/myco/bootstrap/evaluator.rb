
require_relative 'evaluator/context'

module Myco
  class Evaluator
    
    def self.evaluate(cscope, data, &block)
      type, *rest = data
      __send__(:"evaluate_#{type}", cscope, *rest, &block)
    end
    
    def self.evaluation_exception(within, line, e)
      # Make the exception message more helpful without obfuscating the backtrace
      e.instance_variable_set(:@reason_message,
        "While evaluating #{within} on line #{line}:\n#{e.message}")
      raise e
    end
    
    def self.evaluate_file(cscope, line, contents)
      component = ::Myco::Component.new(
        [::Myco::FileToplevel],
        cscope.for_method_definition,
        cscope.active_path.to_s,
        line
      )
      
      inner_cscope = ::Rubinius::ConstantScope.new(component, cscope)
      inner_cscope.myco_evctx.set_myco_file
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_cscope, item) }
      
      component.instance
      
    rescue Exception => e
      filename = cscope.respond_to?(:active_path) && cscope.active_path
      evaluation_exception(filename, line, e)
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
      evaluation_exception("component", line, e)
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
      evaluation_exception("object", line, e)
    end
    
    def self.evaluate_category(cscope, line, name, contents)
      category = cscope.for_method_definition.__category__(name)
      
      inner_cscope = ::Rubinius::ConstantScope.new(category, cscope)
      inner_cscope.myco_evctx.set_myco_category
      contents.reduce(nil) { |_, item| evaluate(inner_cscope, item) }
      
    rescue Exception => e
      evaluation_exception("category", line, e)
    end
    
    def self.evaluate_extension(cscope, line, constant, types, contents)
      component = evaluate(cscope, constant)
      # TODO: inject the given types like includes/super_components
      
      inner_cscope = ::Rubinius::ConstantScope.new(component, cscope)
      inner_cscope.myco_evctx.set_myco_component
      contents.each { |item| evaluate(inner_cscope, item) }
      
      component
    rescue Exception => e
      evaluation_exception("extension", line, e)
    end
    
    def self.decoration_node_type(node_type, *data)
      node_type
    end
    
    def self.decoration_as_name(node_type, *data)
      data[0]
    end
    
    def self.decoration_as_decoration(node_type, *data)
      case node_type
      when :symbol
        [data[0], []]
      when :invoke
        [data[1], data[2]]
      else
        raise NotImplementedError, node_type.to_s
      end
    end
    
    def self.decoration_as_constant_data(node_type, *data)
      [node_type, *data]
    end
    
    def self.evaluate_meme(cscope, decorations, body)
      name = decorations.pop
      # TODO: bring these two cases more semantically close together
      case decoration_node_type(*name)
      when :symbol
        inner_cscope = ::Rubinius::ConstantScope.new(cscope.module, cscope)
        body ||= ->{}
        body.block.instance_variable_set(:@constant_scope, inner_cscope)
        decorations = decorations.reverse.map { |deco| decoration_as_decoration(*deco) }
        inner_cscope.for_method_definition.declare_meme(decoration_as_name(*name), decorations, &body)
      when :const
        constant = decoration_as_constant_data(*name)
        body.block.instance_variable_set(:@constant_scope, cscope)
        assign_constant(cscope, *constant, body.call)
      else
        raise NotImplementedError, decoration_node_type(*name)
      end
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
