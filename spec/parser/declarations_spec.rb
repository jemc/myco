
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
    
end
