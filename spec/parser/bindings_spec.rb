
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
    [[:T_CONSTANT, "Object", 1], [:T_DECLARE_BEGIN, "{", 1],
     [:T_IDENTIFIER, "foo", 2],  [:T_BINDING_BEGIN, "", 2],
       [:T_IDENTIFIER, "one", 2],  [:T_BINDING_END, "", 3],
     [:T_IDENTIFIER, "bar", 3],  [:T_BINDING_BEGIN, "", 3],
       [:T_CONSTANT, "Two", 3],    [:T_BINDING_END, "", 4],
     [:T_IDENTIFIER, "baz", 4],  [:T_BINDING_BEGIN, "", 4],
       [:T_NUMERIC, "3", 4],       [:T_BINDING_END, "", 5],
     [:T_IDENTIFIER, "all", 5],  [:T_BINDING_BEGIN, "", 5],
       [:T_NIL, "nil", 5],         [:T_BINDING_END, "", 6],
     [:T_DECLARE_END, "}", 6]]
  end
  
  lex <<-code do
    Object {
      foo:  {  one  }
      bar  :{  Two  }
      baz    :{3}  
      all:{nil }
    }
  code
    [[:T_CONSTANT, "Object", 1], [:T_DECLARE_BEGIN, "{", 1],
     [:T_IDENTIFIER, "foo", 2],  [:T_BINDING_BEGIN, "{", 2],
       [:T_IDENTIFIER, "one", 2],  [:T_BINDING_END, "}", 2],
     [:T_IDENTIFIER, "bar", 3],  [:T_BINDING_BEGIN, "{", 3],
       [:T_CONSTANT, "Two", 3],    [:T_BINDING_END, "}", 3],
     [:T_IDENTIFIER, "baz", 4],  [:T_BINDING_BEGIN, "{", 4],
       [:T_NUMERIC, "3", 4],       [:T_BINDING_END, "}", 4],
     [:T_IDENTIFIER, "all", 5],  [:T_BINDING_BEGIN, "{", 5],
       [:T_NIL, "nil", 5],         [:T_BINDING_END, "}", 5],
     [:T_DECLARE_END, "}", 6]]
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
    [[:T_CONSTANT, "Object", 1], [:T_DECLARE_BEGIN, "{", 1],
    [:T_IDENTIFIER, "foo", 2],   [:T_BINDING_BEGIN, "{", 2],
      [:T_IDENTIFIER, "one", 2],   [:T_BINDING_END, "}", 4],
    [:T_IDENTIFIER, "bar", 5],   [:T_BINDING_BEGIN, "{", 5],
      [:T_CONSTANT, "Two", 3],     [:T_BINDING_END, "}", 6],
    [:T_IDENTIFIER, "baz", 7],   [:T_BINDING_BEGIN, "{", 7],
      [:T_NUMERIC, "3", 4],        [:T_BINDING_END, "}", 8],
    [:T_IDENTIFIER, "all", 9],   [:T_BINDING_BEGIN, "", 9],
      [:T_NIL, "nil", 5],          [:T_BINDING_END, "", 10],
    [:T_DECLARE_END, "}", 10]]
  end
  
end
