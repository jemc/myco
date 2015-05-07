
require_relative 'evaluator/context'

module Myco
  class Evaluator
    
    def self.evaluate(evctx, data, &block)
      type, *rest = data
      __send__(:"evaluate_#{type}", evctx, *rest, &block)
    end
    
    def self.evaluation_exception(within, loc, e)
      # Make the exception message more helpful without obfuscating the backtrace
      e.instance_variable_set(:@reason_message,
        "While evaluating #{within} at #{loc.inspect}:\n#{e.message}")
      raise e
    end
    
    def self.create_component(evctx, loc, supers)
      ::Myco::Component.new(supers,
        evctx.cscope.for_method_definition,
        evctx.cscope.active_path.to_s,
        loc[0])
    end
    
    def self.evaluate_file(evctx, loc, contents)
      component = create_component(evctx, loc, [::Myco::FileToplevel])
      
      inner_evctx = evctx.nested(component)
      inner_evctx.set_myco_file
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_evctx, item) }
      
      component.instance
      
    rescue Exception => e
      filename = evctx.cscope.respond_to?(:active_path) && evctx.cscope.active_path
      evaluation_exception(filename, loc, e)
    end
    
    def self.evaluate_component(evctx, loc, constant, types, contents)
      supers = types.map { |type| evaluate(evctx, type) }
      component = create_component(evctx, loc, supers)
      
      component.__name__ = constant.last.last.to_sym # TODO: use constant.names.last
      assign_constant(evctx, *constant, component)
      
      inner_evctx = evctx.nested(component)
      inner_evctx.set_myco_component
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_evctx, item) }
      
      component
      
    rescue Exception => e
      evaluation_exception("component", loc, e)
    end
    
    def self.evaluate_object(evctx, loc, types, contents)
      supers = types.map { |type| evaluate(evctx, type) }
      component = create_component(evctx, loc, supers)
      
      inner_evctx = evctx.nested(component)
      inner_evctx.set_myco_component
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_evctx, item) }
      
      component.instance
      
    rescue Exception => e
      evaluation_exception("object", loc, e)
    end
    
    def self.evaluate_category(evctx, loc, name, contents)
      category = evctx.cscope.for_method_definition.__category__(name)
      
      inner_evctx = evctx.nested(category)
      inner_evctx.set_myco_category
      contents.reduce(nil) { |_, item| evaluate(inner_evctx, item) }
      
    rescue Exception => e
      evaluation_exception("category", loc, e)
    end
    
    def self.evaluate_extension(evctx, loc, constant, types, contents)
      component = evaluate(evctx, constant)
      # TODO: inject the given types like includes/super_components
      
      inner_evctx = evctx.nested(component)
      inner_evctx.set_myco_component
      contents.each { |item| evaluate(inner_evctx, item) }
      
      component
    rescue Exception => e
      evaluation_exception("extension", loc, e)
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
    
    def self.evaluate_meme(evctx, loc, decorations, body)
      name = decorations.pop
      # TODO: bring these two cases more semantically close together
      case decoration_node_type(*name)
      when :symbol
        inner_evctx = evctx.nested(evctx.cscope.module)
        body ||= ->{}
        body.block.instance_variable_set(:@constant_scope, inner_evctx.cscope)
        decorations = decorations.reverse.map { |deco| decoration_as_decoration(*deco) }
        inner_evctx.cscope.for_method_definition.declare_meme(decoration_as_name(*name), decorations, &body)
      when :const
        constant = decoration_as_constant_data(*name)
        body.block.instance_variable_set(:@constant_scope, evctx.cscope)
        assign_constant(evctx, *constant, body.call)
      else
        raise NotImplementedError, decoration_node_type(*name)
      end
    end
    
    def self.evaluate_const(evctx, loc, toplevel, names)
      first_name, *rest_names = names
      parent = search_constant(evctx, toplevel, first_name)
      rest_names.reduce(parent) { |parent, name| Rubinius::Type.const_get(parent, name.to_sym) }
    end
    
    
    # TODO: deprecate/remove
    def self.evaluate_from_string(evctx, loc, types, string)
      object = evaluate_object(evctx, loc, types, [])
      object.from_string(string)
    end
    
    def self.assign_constant(evctx, node_type, loc, toplevel, names, value)
      *names, last_name = names
      first_name = names.any? && names.shift
      
      parent = search_constant(evctx, toplevel, first_name)
      parent = names.reduce(parent) { |parent, var| parent.const_get(name) }
      parent.const_set(last_name, value)
      value
    end
    
    def self.search_constant(evctx, toplevel, name=nil)
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
          ::Myco.find_constant(name, evctx.cscope)
        else
          evctx.cscope.for_method_definition
        end
      end
    end
    
  end
end
