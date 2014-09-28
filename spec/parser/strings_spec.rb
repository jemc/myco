
require 'spec_helper'


describe Myco::ToolSet::Parser, "Strings" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    Object {
      str: "foo'\"bar\\\"'baz\\"
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :str, [:array], [:args, :*], [:block, 
        [:lit, "foo'\"bar\\\"'baz\\"]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      str: " \a\b\e\f\n\r\s\t\v \x\y\z"
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :str, [:array], [:args, :*], [:block, 
        [:lit, " \a\b\e\f\n\r\s\t\v xyz"]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      str: 'foo"\'bar\\\'"baz\\'
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :str, [:array], [:args, :*], [:block, 
        [:lit, 'foo"\'bar\\\'"baz\\']]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: "foo '"88"' bar \""null"\" baz"
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block, 
      [:meme, :foo, [:array], [:args, :*], [:block,
        [:dstr, "foo '",
          [:evstr, [:lit, 88]], [:lit, "' bar \""],
          [:evstr, [:null]],    [:lit, "\" baz"],
        ]
      ]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: :"foo '"88"' bar \""null"\" baz"
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block, 
      [:meme, :foo, [:array], [:args, :*], [:block,
        [:dsym, "foo '",
          [:evstr, [:lit, 88]], [:lit, "' bar \""],
          [:evstr, [:null]],    [:lit, "\" baz"],
        ]
      ]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: bar("x" (99) "X", :"y" (1; 2; 3) "Y")
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :*], [:block,
        [:call, [:self], :bar, [:arglist,
          [:dstr, "x", [:evstr, [:lit, 99]], [:lit, "X"]],
          [:dsym, "y",
            [:evstr, [:block, [:lit, 1], [:lit, 2], [:lit, 3]]], [:lit, "Y"]]
        ]]
      ]]
    ]]
  end
  .to_ruby <<-'RUBY'
    (__c__ = ::Myco::Component.new([
      ::Myco.find_constant(:Object, __cscope__)
    ], self, __FILE__, __LINE__)
    __c__.__last__ = __c__.module_eval {(
      __cscope__ = Rubinius::ConstantScope.new(self, __cscope__)
      __cscope__.set_myco_component
      declare_meme(:foo, []) { |*| (
        self.__send__(
          :bar,
          "x#{99}X",
          :"y#{(
            1
            2
            3
          )}Y"
        )
      )}
      __cscope__ = __cscope__.parent
    )}
    __c__.instance)
  RUBY
  
end
