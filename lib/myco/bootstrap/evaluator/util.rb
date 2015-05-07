
module Myco
  class Evaluator
    module Util
      
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
      
      # TODO: remove this utility method by refactoring for simplicity
      def self.decoration_node_type(node_type, *data)
        node_type
      end
      
      # TODO: remove this utility method by refactoring for simplicity
      def self.decoration_as_name(node_type, *data)
        case node_type
        when :invoke
          data[1]
        else
          raise NotImplementedError, node_type.to_s
        end
      end
      
      # TODO: remove this utility method by refactoring for simplicity
      def self.decoration_as_decoration(node_type, *data)
        case node_type
        when :invoke
          [data[1], data[2]]
        else
          raise NotImplementedError, node_type.to_s
        end
      end
      
      # TODO: remove this utility method by refactoring for simplicity
      def self.decoration_as_constant_data(node_type, *data)
        [node_type, *data]
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
end