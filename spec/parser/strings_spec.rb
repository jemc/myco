
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
    ::Myco::Component.new([
      ::Myco.find_constant(:Object)
    ], ::Myco.cscope.for_method_definition, __FILE__, __LINE__)
    .tap { |__c__| __c__.__last__ = __c__.component_eval {(
      declare_meme(:foo, [], nil, ::Myco.cscope.dup) { |*| (
        self.bar(
          "x#{99}X",
          :"y#{(
            1
            2
            3
          )}Y"
        )
      )}
    )}}.instance
  RUBY
  
end
