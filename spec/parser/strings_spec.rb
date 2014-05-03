
require 'spec_helper'


describe Myco::ToolSet::Parser, "Strings" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    Object {
      str: "foo'\"bar\\\"'baz\\"
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:bind, :str, [:array], [:args], [:block, 
        [:lit, "foo'\"bar\\\"'baz\\"]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: "foo '"88"' bar \""nil"\" baz"
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block, 
      [:bind, :foo, [:array], [:args], [:block,
        [:dstr, "foo '",
          [:lit, 88], [:lit, "' bar \""], [:nil], [:lit, "\" baz"]
        ]
      ]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: :"foo '"88"' bar \""nil"\" baz"
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block, 
      [:bind, :foo, [:array], [:args], [:block,
        [:dsym, "foo '",
          [:lit, 88], [:lit, "' bar \""], [:nil], [:lit, "\" baz"]
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
      [:bind, :foo, [:array], [:args], [:block,
        [:call, [:self], :bar, [:arglist,
          [:dstr, "x", [:lit, 99], [:lit, "X"]],
          [:dsym, "y", [:block, [:lit, 1], [:lit, 2], [:lit, 3]], [:lit, "Y"]]
        ]]
      ]]
    ]]
  end
  
end
