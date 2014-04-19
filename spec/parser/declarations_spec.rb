
require 'spec_helper'


describe Myco::ToolSet::Parser, "Declarations" do
  extend SpecHelpers::ParserHelper
  
  lex "Object { }" do
    [[:T_CONSTANT, "Object", 1],
     [:T_DECLARE_BEGIN, "{", 1],
     [:T_DECLARE_END, "}", 1]]
  end
  .parse [:declobj, [:array, [:const, :Object]]]
  
  lex "Object{}" do
    [[:T_CONSTANT, "Object", 1],
     [:T_DECLARE_BEGIN, "{", 1],
     [:T_DECLARE_END, "}", 1]]
  end
  .parse [:declobj, [:array, [:const, :Object]]]
  
  lex <<-code do
    Object {
      
    }
  code
    [[:T_CONSTANT, "Object", 1],
     [:T_DECLARE_BEGIN, "{", 1],
     [:T_DECLARE_END, "}", 3]]
  end
  .parse [:declobj, [:array, [:const, :Object]]]
  
  lex <<-code do
    Object
    {
      
    }
  code
    [[:T_CONSTANT, "Object", 1],
     [:T_DECLARE_BEGIN, "{", 2],
     [:T_DECLARE_END, "}", 4]]
  end
  .parse [:declobj, [:array, [:const, :Object]]]
  
  lex "Foo,Bar,Baz { }" do
    [[:T_CONSTANT, "Foo", 1],[:T_COMMA, ",", 1],
     [:T_CONSTANT, "Bar", 1],[:T_COMMA, ",", 1],
     [:T_CONSTANT, "Baz", 1],
     [:T_DECLARE_BEGIN, "{", 1],
     [:T_DECLARE_END, "}", 1]]
  end
  .parse [:declobj, [:array, [:const, :Foo], [:const, :Bar], [:const, :Baz]]]
  
  lex <<-code do
    Foo  ,  Bar,
    Baz
    {
      
    }
  code
    [[:T_CONSTANT, "Foo", 1],[:T_COMMA, ",", 1],
     [:T_CONSTANT, "Bar", 1],[:T_COMMA, ",", 1],
     [:T_CONSTANT, "Baz", 2],
     [:T_DECLARE_BEGIN, "{", 3],
     [:T_DECLARE_END, "}", 5]]
  end
  .parse [:declobj, [:array, [:const, :Foo], [:const, :Bar], [:const, :Baz]]]
  
  lex "Foo: Object { }" do
    [[:T_CONSTANT, "Foo", 1],   [:T_BINDING_BEGIN, "", 1],
     [:T_CONSTANT, "Object", 1],[:T_DECLARE_BEGIN, "{", 1],
     [:T_DECLARE_END, "}", 1],  [:T_BINDING_END, "", 1]]
  end
  .parse [:cdecl, :Foo, [:declobj, [:array, [:const, :Object]]]]
  
end
