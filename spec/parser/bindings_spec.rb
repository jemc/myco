
require 'spec_helper'


describe Myco::ToolSet::Parser, "Bindings" do
  extend SpecHelpers::ParserHelper
  
  lex <<-code do
    Object {
      foo:    one
      bar  :  Two  
      baz    :3
      all:nil
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "foo"],  [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "one"],  [:T_BINDING_END, ""],
     [:T_IDENTIFIER, "bar"],  [:T_BINDING_BEGIN, ""],
       [:T_CONSTANT, "Two"],    [:T_BINDING_END, ""],
     [:T_IDENTIFIER, "baz"],  [:T_BINDING_BEGIN, ""],
       [:T_NUMERIC, "3"],       [:T_BINDING_END, ""],
     [:T_IDENTIFIER, "all"],  [:T_BINDING_BEGIN, ""],
       [:T_NIL, "nil"],         [:T_BINDING_END, ""],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block, 
    [:bind, :foo, [:nil], [:block, [:lit, :one]]],
    [:bind, :bar, [:nil], [:block, [:const, :Two]]],
    [:bind, :baz, [:nil], [:block, [:lit, 3]]], 
    [:bind, :all, [:nil], [:block, [:nil]]]
  ]]
  
  lex <<-code do
    Object {
      foo:  {  one  }
      bar  :{  Two  }
      baz    :{3}  
      all:{nil }
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "foo"],  [:T_BINDING_BEGIN, "{"],
       [:T_IDENTIFIER, "one"],  [:T_BINDING_END, "}"],
     [:T_IDENTIFIER, "bar"],  [:T_BINDING_BEGIN, "{"],
       [:T_CONSTANT, "Two"],    [:T_BINDING_END, "}"],
     [:T_IDENTIFIER, "baz"],  [:T_BINDING_BEGIN, "{"],
       [:T_NUMERIC, "3"],       [:T_BINDING_END, "}"],
     [:T_IDENTIFIER, "all"],  [:T_BINDING_BEGIN, "{"],
       [:T_NIL, "nil"],         [:T_BINDING_END, "}"],
     [:T_DECLARE_END, "}"]]
  end
  
  lex <<-code do
    Object {
      foo: {
        one
      }
      bar:{ Two
        }
      baz  :{
        3}
      all: \
        nil
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
    [:T_IDENTIFIER, "foo"],   [:T_BINDING_BEGIN, "{"],
      [:T_IDENTIFIER, "one"],   [:T_BINDING_END, "}"],
    [:T_IDENTIFIER, "bar"],   [:T_BINDING_BEGIN, "{"],
      [:T_CONSTANT, "Two"],     [:T_BINDING_END, "}"],
    [:T_IDENTIFIER, "baz"],   [:T_BINDING_BEGIN, "{"],
      [:T_NUMERIC, "3"],        [:T_BINDING_END, "}"],
    [:T_IDENTIFIER, "all"],   [:T_BINDING_BEGIN, ""],
      [:T_NIL, "nil"],          [:T_BINDING_END, ""],
    [:T_DECLARE_END, "}"]]
  end
  
  lex <<-code do
    Object {
      foo:  |a|one
      bar  :  |b|  Two  
      baz    :|c,d,e|  3
      all:
      |a|
      nil
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "foo"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "a"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, ""],
         [:T_IDENTIFIER, "one"], [:T_BINDING_END, ""],
     [:T_IDENTIFIER, "bar"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "b"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, ""],
         [:T_CONSTANT, "Two"], [:T_BINDING_END, ""],
     [:T_IDENTIFIER, "baz"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "c"], [:T_COMMA, ","], 
       [:T_IDENTIFIER, "d"], [:T_COMMA, ","], 
       [:T_IDENTIFIER, "e"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, ""],
         [:T_NUMERIC, "3"], [:T_BINDING_END, ""],
     [:T_IDENTIFIER, "all"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "a"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, ""], 
         [:T_NIL, "nil"], [:T_BINDING_END, ""], 
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block,
    [:bind, :foo, [:args, :a], [:block, [:lit, :one]]],
    [:bind, :bar, [:args, :b], [:block, [:const, :Two]]],
    [:bind, :baz, [:args, :c, :d, :e], [:block, [:lit, 3]]],
    [:bind, :all, [:args, :a], [:block, [:nil]]]
  ]]
  
  lex <<-code do
    Object {
      foo:  |a|{one}
      bar  :  |b|{  Two  }
      baz    :|c,d,e|  {  3
      }
      all:
      |a|
      {
        nil
      }
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "foo"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "a"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, "{"],
         [:T_IDENTIFIER, "one"], [:T_BINDING_END, "}"],
     [:T_IDENTIFIER, "bar"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "b"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, "{"],
         [:T_CONSTANT, "Two"], [:T_BINDING_END, "}"],
     [:T_IDENTIFIER, "baz"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "c"], [:T_COMMA, ","], 
       [:T_IDENTIFIER, "d"], [:T_COMMA, ","], 
       [:T_IDENTIFIER, "e"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, "{"],
         [:T_NUMERIC, "3"], [:T_BINDING_END, "}"],
     [:T_IDENTIFIER, "all"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "a"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, "{"], 
         [:T_NIL, "nil"], [:T_BINDING_END, "}"], 
     [:T_DECLARE_END, "}"]]
  end
  
end
