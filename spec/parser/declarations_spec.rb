
require 'spec_helper'


describe Myco::ToolSet::Parser, "Declarations" do
  extend SpecHelpers::ParserHelper
  
  lex "Object { }" do
    [[:T_CONSTANT, "Object"],
     [:T_DECLARE_BEGIN, "{"],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]]]
  
  lex "Object{}" do
    [[:T_CONSTANT, "Object"],
     [:T_DECLARE_BEGIN, "{"],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]]]
  
  lex <<-code do
    Object {
      
    }
  code
    [[:T_CONSTANT, "Object"],
     [:T_DECLARE_BEGIN, "{"],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]]]
  
  lex <<-code do
    Object
    {
      
    }
  code
    [[:T_CONSTANT, "Object"],
     [:T_DECLARE_BEGIN, "{"],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]]]
  
  lex "Foo,Bar,Baz { }" do
    [[:T_CONSTANT, "Foo"],[:T_COMMA, ","],
     [:T_CONSTANT, "Bar"],[:T_COMMA, ","],
     [:T_CONSTANT, "Baz"],
     [:T_DECLARE_BEGIN, "{"],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Foo], [:const, :Bar], [:const, :Baz]]]
  
  lex <<-code do
    Foo  ,  Bar,
    Baz
    {
      
    }
  code
    [[:T_CONSTANT, "Foo"],[:T_COMMA, ","],
     [:T_CONSTANT, "Bar"],[:T_COMMA, ","],
     [:T_CONSTANT, "Baz"],
     [:T_DECLARE_BEGIN, "{"],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Foo], [:const, :Bar], [:const, :Baz]]]
  
  lex "Foo: Object { }" do
    [[:T_CONSTANT, "Foo"],   [:T_BINDING_BEGIN, ""],
     [:T_CONSTANT, "Object"],[:T_DECLARE_BEGIN, "{"],
     [:T_DECLARE_END, "}"],  [:T_BINDING_END, ""]]
  end
  .parse [:cdecl, :Foo, [:declobj, [:array, [:const, :Object]]]]
  
  lex <<-code do
    Object @@@
      foo
      bar
    @@@
  code
    [[:T_CONSTANT, "Object"],
     [:T_DECLSTR_BEGIN, "@@@"],
     [:T_DECLSTR_LINE,  "      foo"],
     [:T_DECLSTR_LINE,  "      bar"],
     [:T_DECLSTR_END,   "@@@"]]
  end
  
  lex <<-code do
    Object @@@
      @foo
      bar @@@
      @@baz
    @@@
  code
    [[:T_CONSTANT, "Object"],
     [:T_DECLSTR_BEGIN, "@@@"],
     [:T_DECLSTR_LINE,  "      @foo"],
     [:T_DECLSTR_LINE,  "      bar @@@"],
     [:T_DECLSTR_LINE,  "      @@baz"],
     [:T_DECLSTR_END,   "@@@"]]
  end
  
end
