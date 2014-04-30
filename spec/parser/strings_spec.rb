
require 'spec_helper'


describe Myco::ToolSet::Parser, "Strings" do
  extend SpecHelpers::ParserHelper
  
  lex <<-'code' do
    Object {
      str: "foo'\"bar\\\"'baz\\"
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "str"],  [:T_BINDING_BEGIN, ""],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "foo'\\\"bar\\\\\\\"'baz\\\\"],
       [:T_STRING_END,   "\""],
     [:T_BINDING_END, ""], [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block,
    [:bind, :str, [:array], [:args], [:block, 
      [:lit, "foo'\"bar\\\"'baz\\"]]]
  ]]
  
  lex <<-'code' do
    Object {
      foo: "foo '"88"' bar \""nil"\" baz"
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "foo"],  [:T_BINDING_BEGIN, ""],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "foo '"],
       [:T_STRING_END, "\""],  [:T_NUMERIC, "88"],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "' bar \\\""],
       [:T_STRING_END, "\""],  [:T_NIL, "nil"],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "\\\" baz"],
       [:T_STRING_END, "\""],
     [:T_BINDING_END, ""], [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block, 
    [:bind, :foo, [:array], [:args], [:block,
      [:dstr, "foo '",
        [:lit, 88], [:lit, "' bar \""], [:nil], [:lit, "\" baz"]
      ]
    ]]
  ]]
  
end
