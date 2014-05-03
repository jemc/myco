
require 'spec_helper'


describe Myco::ToolSet::Parser, "Strings" do
  extend SpecHelpers::ParserHelper
  
  lex <<-'code' do
    Object {
      str: "foo'\"bar\\\"'baz\\"
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "str"],  [:T_BINDING_BEGIN, ""],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "foo'\\\"bar\\\\\\\"'baz\\\\"],
       [:T_STRING_END,   "\""],
     [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"], [:T_DECLARE_END, "}"]]
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
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "foo"],  [:T_BINDING_BEGIN, ""],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "foo '"],
       [:T_STRING_END, "\""],  [:T_INTEGER, "88"],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "' bar \\\""],
       [:T_STRING_END, "\""],  [:T_NIL, "nil"],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "\\\" baz"],
       [:T_STRING_END, "\""],
     [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"], [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block, 
    [:bind, :foo, [:array], [:args], [:block,
      [:dstr, "foo '",
        [:lit, 88], [:lit, "' bar \""], [:nil], [:lit, "\" baz"]
      ]
    ]]
  ]]
  
  lex <<-'code' do
    Object {
      foo: :"foo '"88"' bar \""nil"\" baz"
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "foo"],  [:T_BINDING_BEGIN, ""],
       [:T_SYMSTR_BEGIN, "\""], [:T_SYMSTR_BODY, "foo '"],
       [:T_SYMSTR_END, "\""],  [:T_INTEGER, "88"],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "' bar \\\""],
       [:T_STRING_END, "\""],  [:T_NIL, "nil"],
       [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "\\\" baz"],
       [:T_STRING_END, "\""],
     [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"], [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block, 
    [:bind, :foo, [:array], [:args], [:block,
      [:dsym, "foo '",
        [:lit, 88], [:lit, "' bar \""], [:nil], [:lit, "\" baz"]
      ]
    ]]
  ]]
  
  lex <<-'code' do
    Object {
      foo: bar("x" (99) "X", :"y" (1; 2; 3) "Y")
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"], [:T_EXPR_SEP, "\n"],
     [:T_IDENTIFIER, "foo"], [:T_BINDING_BEGIN, ""],
       [:T_IDENTIFIER, "bar"], [:T_ARGS_BEGIN, "("],
         [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "x"], [:T_STRING_END, "\""],
         [:T_PAREN_BEGIN, "("], [:T_INTEGER, "99"], [:T_PAREN_END, ")"],
         [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "X"], [:T_STRING_END, "\""],
       [:T_ARG_SEP, ","],
         [:T_SYMSTR_BEGIN, "\""], [:T_SYMSTR_BODY, "y"], [:T_SYMSTR_END, "\""],
         [:T_PAREN_BEGIN, "("],
           [:T_INTEGER, "1"], [:T_EXPR_SEP, ";"],
           [:T_INTEGER, "2"], [:T_EXPR_SEP, ";"],
           [:T_INTEGER, "3"], [:T_PAREN_END, ")"],
         [:T_STRING_BEGIN, "\""], [:T_STRING_BODY, "Y"], [:T_STRING_END, "\""],
      [:T_ARGS_END, ")"], [:T_BINDING_END, ""], [:T_EXPR_SEP, "\n"],
    [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block,
    [:bind, :foo, [:array], [:args], [:block,
      [:call, [:self], :bar, [:arglist,
        [:dstr, "x", [:lit, 99], [:lit, "X"]],
        [:dsym, "y", [:block, [:lit, 1], [:lit, 2], [:lit, 3]], [:lit, "Y"]]
      ]]
    ]]
  ]]
  
end
