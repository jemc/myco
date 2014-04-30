
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
      foo: "String#to_s of '#{88}' will return \"#{88}\" when \#{called}"
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "foo"],  [:T_BINDING_BEGIN, ""],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "String#to_s of '"],
       [:T_BINDING_BEGIN, "\#{"], [:T_NUMERIC, "88"],
       [:T_BINDING_END, "}"],  [:T_STRING_BODY, "' will return \\\""],
       [:T_BINDING_BEGIN, "\#{"], [:T_NUMERIC, "88"],
       [:T_BINDING_END, "}"],  [:T_STRING_BODY, "\\\" when \\\#{called}"],
       [:T_STRING_END, "\""],
     [:T_BINDING_END, ""], [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block, 
    [:bind, :foo, [:array], [:args], [:block, 
      [:dstr, "String#to_s of '", 
        [:block, [:lit, 88]], 
        [:lit, "' will return \""], 
        [:block, [:lit, 88]], 
        [:lit, "\" when \#{called}"]]
      ]
    ]
  ]]
  
end
