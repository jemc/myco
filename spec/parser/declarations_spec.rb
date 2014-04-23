
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
     [:T_DECLSTR_BODY,  <<-DECLSTR],
      foo
      bar
    DECLSTR
     [:T_DECLSTR_END,   "@@@"]]
  end
  .parse [:declstr, [:array, [:const, :Object]], [:str, <<-DECLSTR]]
      foo
      bar
  DECLSTR
  
  lex <<-code do
    Foo: Object @@@
      bar
    @@@
  code
    [[:T_CONSTANT, "Foo"],   [:T_BINDING_BEGIN, ""],
     [:T_CONSTANT, "Object"],
     [:T_DECLSTR_BEGIN, "@@@"],
     [:T_DECLSTR_BODY, "      bar\n"],
     [:T_DECLSTR_END, "@@@"],
     [:T_BINDING_END, ""]]
  end
  .parse [:cdecl, :Foo, [:declstr, [:array, [:const, :Object]], 
                                   [:str, "      bar\n"]]]
  
  lex <<-code do
    Object @@@
      @foo
      bar @@@
      @@baz
    @@@
  code
    [[:T_CONSTANT, "Object"],
     [:T_DECLSTR_BEGIN, "@@@"],
     [:T_DECLSTR_BODY,  <<-DECLSTR],
      @foo
      bar @@@
      @@baz
    DECLSTR
     [:T_DECLSTR_END,   "@@@"]]
  end
  
  lex <<-code do
    Object foo
      bar
    foo
  code
    [[:T_CONSTANT, "Object"],
     [:T_DECLSTR_BEGIN, "foo"],
     [:T_DECLSTR_BODY,  <<-DECLSTR],
      bar
    DECLSTR
     [:T_DECLSTR_END,   "foo"]]
  end
  
  lex <<-code do
    Object 123_TEST
      foo
    TEST_321
  code
    [[:T_CONSTANT, "Object"],
     [:T_DECLSTR_BEGIN, "123_TEST"],
     [:T_DECLSTR_BODY,  <<-DECLSTR],
      foo
    DECLSTR
     [:T_DECLSTR_END,   "TEST_321"]]
  end
  
  lex <<-code do
    Object >)+-foo><BAR+-]]]}}}
      foo
    {{{[[[-+BAR><foo-+(<
  code
    [[:T_CONSTANT, "Object"],
     [:T_DECLSTR_BEGIN, ">)+-foo><BAR+-]]]}}}"],
     [:T_DECLSTR_BODY,  <<-DECLSTR],
      foo
    DECLSTR
     [:T_DECLSTR_END,   "{{{[[[-+BAR><foo-+(<"]]
  end
  
end
