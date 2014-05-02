
require 'spec_helper'


describe Myco::ToolSet::Parser, "Decorations" do
  extend SpecHelpers::ParserHelper
  
  lex <<-'code' do
    Object {
      on foo: nil
      one two three: nil
      sym "str.ng": nil
    }
  code
    [[:T_CONSTANT, "Object"], [:T_DECLARE_BEGIN, "{"],
     [:T_IDENTIFIER, "on"], [:T_IDENTIFIER, "foo"],
       [:T_BINDING_BEGIN, ""], [:T_NIL, "nil"], [:T_BINDING_END, ""],
     [:T_IDENTIFIER, "one"], [:T_IDENTIFIER, "two"], [:T_IDENTIFIER, "three"],
       [:T_BINDING_BEGIN, ""], [:T_NIL, "nil"], [:T_BINDING_END, ""],
     [:T_IDENTIFIER, "sym"], [:T_STRING_BEGIN, "\""],
       [:T_STRING_BODY, "str.ng"], [:T_STRING_END, "\""],
       [:T_BINDING_BEGIN, ""], [:T_NIL, "nil"], [:T_BINDING_END, ""],
     [:T_DECLARE_END, "}"]]
  end
  .parse [:declobj, [:array, [:const, :Object]], [:block,
    [:bind, :foo,   [:array, [:lit, :on]],
      [:args], [:block, [:nil]]],
    [:bind, :three, [:array, [:lit, :two], [:lit, :one]],
      [:args], [:block, [:nil]]],
    [:bind, :"str.ng", [:array, [:lit, :sym]],
      [:args], [:block, [:nil]]]
  ]]
  
end
