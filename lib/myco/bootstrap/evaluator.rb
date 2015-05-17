
require_relative 'evaluator/context'
require_relative 'evaluator/util'

module Myco
  class Evaluator
    
    @util = Util
    
    def self.evaluate(evctx, data, &block)
      type, *rest = data
      __send__(:"evaluate_#{type}", evctx, *rest, &block)
    end
    
    def self.evaluate_file(evctx, loc, contents)
      component = @util.create_component(evctx, loc, [::Myco::FileToplevel])
      
      inner_evctx = evctx.nested(component)
      inner_evctx.set_myco_file
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_evctx, item) }
      
      component.instance
      
    rescue Exception => e
      @util.evaluation_exception(evctx.filename, loc, e)
    end
    
    def self.evaluate_component(evctx, loc, constant, types, contents)
      supers = types.map { |type| evaluate(evctx, type) }
      component = @util.create_component(evctx, loc, supers)
      
      component.__name__ = constant.last.last.to_sym # TODO: use constant.names.last
      @util.assign_constant(evctx, *constant, component)
      
      inner_evctx = evctx.nested(component)
      inner_evctx.set_myco_component
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_evctx, item) }
      
      component
      
    rescue Exception => e
      @util.evaluation_exception(:component, loc, e)
    end
    
    def self.evaluate_object(evctx, loc, types, contents)
      supers = types.map { |type| evaluate(evctx, type) }
      component = @util.create_component(evctx, loc, supers)
      
      inner_evctx = evctx.nested(component)
      inner_evctx.set_myco_component
      component.__last__ = contents.reduce(nil) { |_, item| evaluate(inner_evctx, item) }
      
      component.instance
      
    rescue Exception => e
      @util.evaluation_exception(:object, loc, e)
    end
    
    def self.evaluate_category(evctx, loc, name, contents)
      category = evctx.cscope.for_method_definition.__category__(name)
      
      inner_evctx = evctx.nested(category)
      inner_evctx.set_myco_category
      contents.reduce(nil) { |_, item| evaluate(inner_evctx, item) }
      
    rescue Exception => e
      @util.evaluation_exception(:category, loc, e)
    end
    
    def self.evaluate_extension(evctx, loc, constant, types, contents)
      component = evaluate(evctx, constant)
      # TODO: inject the given types like includes/super_components
      
      inner_evctx = evctx.nested(component)
      inner_evctx.set_myco_component
      contents.each { |item| evaluate(inner_evctx, item) }
      
      component
    rescue Exception => e
      @util.evaluation_exception(:extension, loc, e)
    end
    
    def self.evaluate_meme(evctx, loc, decorations, body)
      name = decorations.pop
      # TODO: bring these two cases more semantically close together
      case @util.decoration_node_type(*name)
      when :invoke
        inner_evctx = evctx.nested(evctx.cscope.module)
        body ||= ->{}
        body.block.instance_variable_set(:@constant_scope, inner_evctx.cscope)
        decorations = decorations.reverse.map { |deco| @util.decoration_as_decoration(*deco) }
        inner_evctx.cscope.for_method_definition.declare_meme(@util.decoration_as_name(*name), decorations, &body)
      when :constant
        constant = @util.decoration_as_constant_data(*name)
        body.block.instance_variable_set(:@constant_scope, evctx.cscope)
        @util.assign_constant(evctx, *constant, body.call)
      else
        raise NotImplementedError, decoration_node_type(*name)
      end
    rescue Exception => e
      @util.evaluation_exception(:meme, loc, e)
    end
    
    def self.evaluate_constant(evctx, loc, toplevel, names)
      first_name, *rest_names = names
      parent = @util.search_constant(evctx, toplevel, first_name)
      rest_names.reduce(parent) { |parent, name| Rubinius::Type.const_get(parent, name.to_sym) }
    rescue Exception => e
      @util.evaluation_exception(:constant, loc, e)
    end
    
    # TODO: deprecate/remove
    def self.evaluate_declare_string(evctx, loc, types, string)
      object = evaluate_object(evctx, loc, types, [])
      object.from_string(string)
    rescue Exception => e
      @util.evaluation_exception(:declare_string, loc, e)
    end
    
  end
end
