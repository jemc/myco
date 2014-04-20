
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
  
end
