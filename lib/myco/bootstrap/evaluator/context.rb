
module Rubinius
  class ConstantScope
    def myco_evctx
      @myco_evctx ||= Myco::Evaluator::Context.new(self)
    end
  end
end

module Myco
  class Evaluator
    class Context
      
      def initialize(cscope)
        @cscope = cscope
      end
      
      def inspect_list
        mod = @myco_meme || @myco_category || @myco_component || @myco_file || @cscope.module
        this_item = "0x#{object_id.to_s(16)} #{mod}"
        @cscope.parent ? "#{this_item}, #{@cscope.parent.myco_evctx.inspect_list}" : this_item
      end
      
      def inspect
        "#<#{self.class}:#{inspect_list}>"
      end
      
      attr_reader :cscope
      
      attr_reader :myco_file
      attr_reader :myco_component
      attr_reader :myco_category
      attr_reader :is_myco_level
      
      attr_reader :myco_meme
      
      # TODO: Can this be more graceful and more eager?
      def myco_file
        @myco_file ||= @cscope.parent && @cscope.parent.myco_evctx.myco_file
      end
      
      def myco_levels
        @myco_levels ||= (@cscope.parent ? @cscope.parent.myco_evctx.myco_levels.dup : [::Myco])
      end
      
      def myco_parent
        parent = @cscope.parent
        parent ? (
          parent = parent.myco_evctx
          parent.is_myco_level ? parent : parent.myco_parent
        ) : nil
      end
      
      def set_myco_file
        raise "myco_file already set for #{self.inspect}" \
          if @myco_file
        @myco_component = @cscope.module
        @myco_file      = @cscope.module
        
        @myco_file.instance_variable_set(:@constant_scope, @cscope)
        
        myco_levels << @myco_file
        @is_myco_level = true
      end
      
      def set_myco_component
        raise "myco_component already set for #{self.inspect}" \
          if @myco_component
        @myco_component = @cscope.module
        @myco_file      = @cscope.parent.myco_evctx.myco_file
        
        raise "No myco_file in parents for #{self.inspect}" unless @myco_file
        
        myco_levels << @myco_component
        @is_myco_level = true
      end
      
      def set_myco_category
        raise "myco_category already set for #{self.inspect}" \
          if @myco_category
        @myco_category  = @cscope.module
        @myco_component = @cscope.parent.myco_evctx.myco_component
        @myco_file      = @cscope.parent.myco_evctx.myco_file
        
        raise "No myco_component in parents for #{self.inspect}" unless @myco_component
        raise "No myco_file in parents for #{self.inspect}"      unless @myco_file
        
        myco_levels << @myco_category
        @is_myco_level = true
      end
      
      def set_myco_meme value
        raise "myco_meme already set for #{self.inspect}" \
          if @myco_meme
        @myco_meme = value
      end
      
      def get_myco_constant_ref(name)
        @myco_constant_refs ||= Rubinius::LookupTable.new
        @myco_constant_refs[name] ||= ::Myco::ConstantReference.new(name, @cscope)
      end
      
    end
  end
end
