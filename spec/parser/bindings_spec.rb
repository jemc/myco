
require 'spec_helper'


describe Myco::ToolSet::Parser, "Bindings" do
  extend SpecHelpers::ParserHelper
  
  lex <<-code do
    Object {
      foo:    one
      bar  :  Two  
      baz    :3
      all:nil
      else: "what"
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
     [:T_IDENTIFIER, "else"], [:T_BINDING_BEGIN, ""],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "what"],
       [:T_STRING_END, "\""], [:T_BINDING_END, ""],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block, 
    [:bind, :foo,  [:array], [:args], [:block, [:lambig, :one]]],
    [:bind, :bar,  [:array], [:args], [:block, [:const, :Two]]],
    [:bind, :baz,  [:array], [:args], [:block, [:lit, 3]]],
    [:bind, :all,  [:array], [:args], [:block, [:nil]]],
    [:bind, :else, [:array], [:args], [:block, [:lit, "what"]]]
  ]]
  
  lex <<-code do
    Object {
      foo:  {  one  }
      bar  :{  Two  }
      baz    :{3}  
      all:{nil }
      else: { "what" }
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
     [:T_IDENTIFIER, "else"], [:T_BINDING_BEGIN, "{"],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "what"],
       [:T_STRING_END, "\""], [:T_BINDING_END, "}"],
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
      bar  :  ||  Two  
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
       [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, ""],
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
    [:bind, :foo, [:array], [:args, :a], [:block, [:lambig, :one]]],
    [:bind, :bar, [:array], [:args], [:block, [:const, :Two]]],
    [:bind, :baz, [:array], [:args, :c, :d, :e], [:block, [:lit, 3]]],
    [:bind, :all, [:array], [:args, :a], [:block, [:nil]]]
  ]]
  
  lex <<-code do
    Object {
      foo:  |a|{one}
      bar  :  ||{  Two  }
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
       [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, "{"],
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
  
  lex <<-code do
    Object {
      foo: { func() }
      bar: { func(1,2,nil) }
      baz: {
        func(
          1,
          2,
          nil
        )
      }
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "foo"], [:T_BINDING_BEGIN, "{"],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("], [:T_ARGS_END, ")"],
       [:T_BINDING_END, "}"],
     [:T_IDENTIFIER, "bar"], [:T_BINDING_BEGIN, "{"],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("],
         [:T_NUMERIC, "1"], [:T_COMMA, ","],
         [:T_NUMERIC, "2"], [:T_COMMA, ","],
         [:T_NIL, "nil"], [:T_ARGS_END, ")"], [:T_BINDING_END, "}"],
     [:T_IDENTIFIER, "baz"], [:T_BINDING_BEGIN, "{"],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("], 
         [:T_NUMERIC, "1"], [:T_COMMA, ","],
         [:T_NUMERIC, "2"], [:T_COMMA, ","],
         [:T_NIL, "nil"], [:T_ARGS_END, ")"], [:T_BINDING_END, "}"],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block,
    [:bind, :foo, [:array], [:args], [:block,
      [:call, [:self], :func, [:arglist]]]],
    [:bind, :bar, [:array], [:args], [:block,
      [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:nil]]]]],
    [:bind, :baz, [:array], [:args], [:block,
      [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:nil]]]]]
  ]]
  
  lex <<-code do
    Object {
      foo: func()
      bar: func(1,2,nil)
      baz:
      func(
        1,
        2,
        nil
      )
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "foo"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("], [:T_ARGS_END, ")"],
       [:T_BINDING_END, ""],
     [:T_IDENTIFIER, "bar"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("],
         [:T_NUMERIC, "1"], [:T_COMMA, ","],
         [:T_NUMERIC, "2"], [:T_COMMA, ","],
         [:T_NIL, "nil"], [:T_ARGS_END, ")"], [:T_BINDING_END, ""],
     [:T_IDENTIFIER, "baz"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("], 
         [:T_NUMERIC, "1"], [:T_COMMA, ","],
         [:T_NUMERIC, "2"], [:T_COMMA, ","],
         [:T_NIL, "nil"], [:T_ARGS_END, ")"], [:T_BINDING_END, ""],
     [:T_DECLARE_END, "}"]]
  end
  
  lex <<-code do
    Object {
      foo: { func() }
      bar: { func(1,2,nil) }
      baz: {
        func(
          1,
          2,
          nil
        )
      }
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "foo"], [:T_BINDING_BEGIN, "{"],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("], [:T_ARGS_END, ")"],
       [:T_BINDING_END, "}"],
     [:T_IDENTIFIER, "bar"], [:T_BINDING_BEGIN, "{"],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("],
         [:T_NUMERIC, "1"], [:T_COMMA, ","],
         [:T_NUMERIC, "2"], [:T_COMMA, ","],
         [:T_NIL, "nil"], [:T_ARGS_END, ")"], [:T_BINDING_END, "}"],
     [:T_IDENTIFIER, "baz"], [:T_BINDING_BEGIN, "{"],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("], 
         [:T_NUMERIC, "1"], [:T_COMMA, ","],
         [:T_NUMERIC, "2"], [:T_COMMA, ","],
         [:T_NIL, "nil"], [:T_ARGS_END, ")"], [:T_BINDING_END, "}"],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block,
    [:bind, :foo, [:array], [:args], [:block,
      [:call, [:self], :func, [:arglist]]]],
    [:bind, :bar, [:array], [:args], [:block,
      [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:nil]]]]],
    [:bind, :baz, [:array], [:args], [:block,
      [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:nil]]]]]
  ]]
  
  lex <<-code do
    Object {
      foo: obj.func
      bar: obj.other.func(1,2,nil).other(5,6)
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "foo"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "obj"], [:T_DOT, "."],
       [:T_IDENTIFIER, "func"], [:T_BINDING_END, ""],
     [:T_IDENTIFIER, "bar"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "obj"], [:T_DOT, "."],
       [:T_IDENTIFIER, "other"], [:T_DOT, "."],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("],
         [:T_NUMERIC, "1"], [:T_COMMA, ","],
         [:T_NUMERIC, "2"], [:T_COMMA, ","],
         [:T_NIL, "nil"], [:T_ARGS_END, ")"], [:T_DOT, "."],
       [:T_IDENTIFIER, "other"], [:T_ARGS_BEGIN, "("],
         [:T_NUMERIC, "5"], [:T_COMMA, ","],
         [:T_NUMERIC, "6"], [:T_ARGS_END, ")"],
     [:T_BINDING_END, ""], [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block,
    [:bind, :foo, [:array], [:args], [:block,
      [:call, [:lambig, :obj], :func, [:arglist]]]],
    [:bind, :bar, [:array], [:args], [:block,
      [:call,
        [:call,
          [:call, [:lambig, :obj], :other, [:arglist]],
           :func, [:arglist, [:lit, 1], [:lit, 2], [:nil]]],
         :other, [:arglist, [:lit, 5], [:lit, 6]]]]]
  ]]
  
  
end
