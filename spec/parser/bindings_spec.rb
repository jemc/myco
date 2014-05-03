
require 'spec_helper'


describe Myco::ToolSet::Parser, "Bindings" do
  extend SpecHelpers::ParserHelper
  
  lex <<-'code' do
    Object {
      foo:    one
      bar  :  Two  
      baz    :3
      deci  : 3.88
      ary :  [1,2, 3,
              4
              5,,
              6
              
              7,
             ]
      all:nil
      str  : "string"
      sym  :  :bol
      ssym : :"with spaces"
      t:    true
      f:    false
      "x y" : z
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "foo"],  [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "one"],  [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "bar"],  [:T_BINDING_BEGIN, ""],
       [:T_CONSTANT, "Two"],    [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "baz"],  [:T_BINDING_BEGIN, ""],
       [:T_INTEGER, "3"],       [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "deci"], [:T_BINDING_BEGIN, ""],
       [:T_FLOAT, "3.88"],      [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "ary"], [:T_BINDING_BEGIN, ""], [:T_ARRAY_BEGIN, "["],
       [:T_INTEGER, "1"], [:T_ARG_SEP, ","], [:T_INTEGER, "2"],
       [:T_ARG_SEP, ","], [:T_INTEGER, "3"], [:T_ARG_SEP, ","],
       [:T_ARG_SEP, "\n"], [:T_INTEGER, "4"], [:T_ARG_SEP, "\n"],
       [:T_INTEGER, "5"], [:T_ARG_SEP, ","], [:T_ARG_SEP, ","],
       [:T_ARG_SEP, "\n"], [:T_INTEGER, "6"], [:T_ARG_SEP, "\n"],
       [:T_ARG_SEP, "\n"], [:T_INTEGER, "7"], [:T_ARG_SEP, ","],
       [:T_ARG_SEP, "\n"], [:T_ARRAY_END, "]"],
                                [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "all"],  [:T_BINDING_BEGIN, ""],
       [:T_NIL, "nil"],         [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "str"], [:T_BINDING_BEGIN, ""],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "string"],
       [:T_STRING_END, "\""],   [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "sym"],  [:T_BINDING_BEGIN, ""],
       [:T_SYMBOL, "bol"],      [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "ssym"], [:T_BINDING_BEGIN, ""],
       [:T_SYMSTR_BEGIN, "\""], [:T_SYMSTR_BODY, "with spaces"],
       [:T_SYMSTR_END, "\""],   [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "t"],    [:T_BINDING_BEGIN, ""],
       [:T_TRUE, "true"],       [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "f"],    [:T_BINDING_BEGIN, ""],
       [:T_FALSE, "false"],     [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "x y"],
       [:T_STRING_END, "\""], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "z"],    [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block, 
    [:bind, :foo,   [:array], [:args], [:block, [:lambig, :one]]],
    [:bind, :bar,   [:array], [:args], [:block, [:const, :Two]]],
    [:bind, :baz,   [:array], [:args], [:block, [:lit, 3]]],
    [:bind, :deci,  [:array], [:args], [:block, [:lit, 3.88]]],
    [:bind, :ary,   [:array], [:args], [:block, [:array,
      [:lit, 1], [:lit, 2], [:lit, 3], [:lit, 4],
      [:lit, 5], [:lit, 6], [:lit, 7]]]],
    [:bind, :all,   [:array], [:args], [:block, [:nil]]],
    [:bind, :str,   [:array], [:args], [:block, [:lit, "string"]]],
    [:bind, :sym,   [:array], [:args], [:block, [:lit, :bol]]],
    [:bind, :ssym,  [:array], [:args], [:block, [:lit, :"with spaces"]]],
    [:bind, :t,     [:array], [:args], [:block, [:true]]],
    [:bind, :f,     [:array], [:args], [:block, [:false]]],
    [:bind, :"x y", [:array], [:args], [:block, [:lambig, :z]]],
  ]]
  
  lex <<-'code' do
    Object {
      a: 1 + 2 * 3
      b: 1 / 2 - 3
      x: a . b % 3
      y: a ** b <=> x
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "a"],    [:T_BINDING_BEGIN, ""],
       [:T_INTEGER, "1"], [:T_OP_PLUS, "+"], [:T_INTEGER, "2"],
                          [:T_OP_MULT, "*"], [:T_INTEGER, "3"],
     [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "b"], [:T_BINDING_BEGIN, ""],
       [:T_INTEGER, "1"], [:T_OP_DIV, "/"], [:T_INTEGER, "2"],
                          [:T_OP_MINUS, "-"], [:T_INTEGER, "3"],
     [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "x"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "a"], [:T_DOT, "."], [:T_IDENTIFIER, "b"],
                             [:T_OP_MOD, "%"], [:T_INTEGER, "3"],
     [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "y"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "a"], [:T_OP_EXP, "**"], [:T_IDENTIFIER, "b"],
                             [:T_OP_COMPARE, "<=>"], [:T_IDENTIFIER, "x"],
       [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block,
    [:bind, :a, [:array], [:args], [:block,
      [:call, [:lit, 1], :+, [:arglist,
              [:call, [:lit, 2], :*, [:arglist, [:lit, 3]]]]]
    ]],
    [:bind, :b, [:array], [:args], [:block,
      [:call, [:call, [:lit, 1], :/, [:arglist, [:lit, 2]]], 
              :-, [:arglist, [:lit, 3]]]
    ]],
    [:bind, :x, [:array], [:args], [:block,
      [:call, [:call, [:lambig, :a], :b, [:arglist]],
              :%, [:arglist, [:lit, 3]]]
    ]],
    [:bind, :y, [:array], [:args], [:block,
      [:call, [:call, [:lambig, :a], :**, [:arglist, [:lambig, :b]]], 
              :<=>, [:arglist, [:lambig, :x]]]
    ]]
  ]]
  
  lex <<-'code' do
    Object {
      foo:  {  one  }
      bar  :{  Two  }
      baz    :{3}  
      all:{nil }
      else: { "what" }
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "foo"],  [:T_BINDING_BEGIN, "{"],
       [:T_IDENTIFIER, "one"],  [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "bar"],  [:T_BINDING_BEGIN, "{"],
       [:T_CONSTANT, "Two"],    [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "baz"],  [:T_BINDING_BEGIN, "{"],
       [:T_INTEGER, "3"],       [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "all"],  [:T_BINDING_BEGIN, "{"],
       [:T_NIL, "nil"],         [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "else"], [:T_BINDING_BEGIN, "{"],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "what"],
       [:T_STRING_END, "\""],   [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_DECLARE_END, "}"]]
  end
  
  lex <<-'code' do
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
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "foo"],   [:T_BINDING_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
       [:T_IDENTIFIER, "one"],   [:T_EXPR_SEP, "\n"],
       [:T_BINDING_END, "}"],  [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "bar"],   [:T_BINDING_BEGIN, "{"],
       [:T_CONSTANT, "Two"],     [:T_EXPR_SEP, "\n"],
       [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "baz"],   [:T_BINDING_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
       [:T_INTEGER, "3"],        [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "all"],   [:T_BINDING_BEGIN, ""],
       [:T_NIL, "nil"],          [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_DECLARE_END, "}"]]
  end
  
  lex <<-'code' do
    Object {
      foo:  |a|one
      bar  :  ||  Two  
      baz    :|c,d,e|  3
      all:
      |a|
      nil
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "foo"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "a"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, ""],
         [:T_IDENTIFIER, "one"], [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "bar"], [:T_PARAMS_BEGIN, "|"],
       [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, ""],
         [:T_CONSTANT, "Two"], [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "baz"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "c"], [:T_ARG_SEP, ","], 
       [:T_IDENTIFIER, "d"], [:T_ARG_SEP, ","], 
       [:T_IDENTIFIER, "e"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, ""],
         [:T_INTEGER, "3"], [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "all"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "a"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, ""], 
         [:T_NIL, "nil"], [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block,
    [:bind, :foo, [:array], [:args, :a], [:block, [:lambig, :one]]],
    [:bind, :bar, [:array], [:args], [:block, [:const, :Two]]],
    [:bind, :baz, [:array], [:args, :c, :d, :e], [:block, [:lit, 3]]],
    [:bind, :all, [:array], [:args, :a], [:block, [:nil]]]
  ]]
  
  lex <<-'code' do
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
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "foo"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "a"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, "{"],
         [:T_IDENTIFIER, "one"], [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "bar"], [:T_PARAMS_BEGIN, "|"],
       [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, "{"],
         [:T_CONSTANT, "Two"], [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "baz"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "c"], [:T_ARG_SEP, ","], 
       [:T_IDENTIFIER, "d"], [:T_ARG_SEP, ","], 
       [:T_IDENTIFIER, "e"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, "{"],
         [:T_INTEGER, "3"], [:T_EXPR_SEP, "\n"],
         [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "all"], [:T_PARAMS_BEGIN, "|"],
       [:T_IDENTIFIER, "a"], [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, "{"],
         [:T_EXPR_SEP, "\n"], [:T_NIL, "nil"], [:T_EXPR_SEP, "\n"],
       [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"], [:T_DECLARE_END, "}"]]
  end
  
  lex <<-'code' do
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
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "foo"], [:T_BINDING_BEGIN, "{"],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("], [:T_ARGS_END, ")"],
       [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "bar"], [:T_BINDING_BEGIN, "{"],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("],
         [:T_INTEGER, "1"], [:T_ARG_SEP, ","],
         [:T_INTEGER, "2"], [:T_ARG_SEP, ","],
         [:T_NIL, "nil"], [:T_ARGS_END, ")"],
       [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "baz"], [:T_BINDING_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("], [:T_ARG_SEP, "\n"],
         [:T_INTEGER, "1"], [:T_ARG_SEP, ","], [:T_ARG_SEP, "\n"],
         [:T_INTEGER, "2"], [:T_ARG_SEP, ","], [:T_ARG_SEP, "\n"],
         [:T_NIL, "nil"], [:T_ARG_SEP, "\n"], [:T_ARGS_END, ")"],
       [:T_EXPR_SEP, "\n"], [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
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
  
  lex <<-'code' do
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
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "foo"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("], [:T_ARGS_END, ")"],
       [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "bar"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("],
         [:T_INTEGER, "1"], [:T_ARG_SEP, ","],
         [:T_INTEGER, "2"], [:T_ARG_SEP, ","],
         [:T_NIL, "nil"], [:T_ARGS_END, ")"],
       [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "baz"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("], [:T_ARG_SEP, "\n"],
         [:T_INTEGER, "1"], [:T_ARG_SEP, ","], [:T_ARG_SEP, "\n"],
         [:T_INTEGER, "2"], [:T_ARG_SEP, ","], [:T_ARG_SEP, "\n"],
         [:T_NIL, "nil"], [:T_ARG_SEP, "\n"], [:T_ARGS_END, ")"],
       [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_DECLARE_END, "}"]]
  end
  
  lex <<-'code' do
    Object {
      foo: obj.func
      bar: obj.other.func(1,2,nil).other(5,6)
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "foo"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "obj"], [:T_DOT, "."],
       [:T_IDENTIFIER, "func"], [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "bar"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "obj"], [:T_DOT, "."],
       [:T_IDENTIFIER, "other"], [:T_DOT, "."],
       [:T_IDENTIFIER, "func"], [:T_ARGS_BEGIN, "("],
         [:T_INTEGER, "1"], [:T_ARG_SEP, ","],
         [:T_INTEGER, "2"], [:T_ARG_SEP, ","],
         [:T_NIL, "nil"], [:T_ARGS_END, ")"], [:T_DOT, "."],
       [:T_IDENTIFIER, "other"], [:T_ARGS_BEGIN, "("],
         [:T_INTEGER, "5"], [:T_ARG_SEP, ","],
         [:T_INTEGER, "6"], [:T_ARGS_END, ")"],
     [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"], [:T_DECLARE_END, "}"]]
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
  
  lex <<-'code' do
    Object {
      foo: |a,b, c,
        d
        e,,
        f
        
        g,
      | { }
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
      [:T_IDENTIFIER, "foo"], [:T_PARAMS_BEGIN, "|"],
        [:T_IDENTIFIER, "a"], [:T_ARG_SEP, ","],
        [:T_IDENTIFIER, "b"], [:T_ARG_SEP, ","],
        [:T_IDENTIFIER, "c"], [:T_ARG_SEP, ","], [:T_ARG_SEP, "\n"],
        [:T_IDENTIFIER, "d"], [:T_ARG_SEP, "\n"],
        [:T_IDENTIFIER, "e"], [:T_ARG_SEP, ","],
          [:T_ARG_SEP, ","], [:T_ARG_SEP, "\n"],
        [:T_IDENTIFIER, "f"], [:T_ARG_SEP, "\n"], [:T_ARG_SEP, "\n"],
        [:T_IDENTIFIER, "g"], [:T_ARG_SEP, ","], [:T_ARG_SEP, "\n"],
      [:T_PARAMS_END, "|"], [:T_BINDING_BEGIN, "{"],
      [:T_BINDING_END, "}"], [:T_EXPR_SEP, "\n"],
    [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block,
    [:bind, :foo, [:array], [:args, :a, :b, :c, :d, :e, :f, :g], [:nil]]
  ]]
  
end
