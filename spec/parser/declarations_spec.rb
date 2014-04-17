
require 'spec_helper'


describe Myco::ToolSet::Parser, "Declarations" do
  extend SpecHelpers::ParserHelper
  
  lex "Object { }" do
    [[:T_CONSTANT, "Object", 1],
     [:T_DECLARE_BEGIN, "{", 1],
     [:T_DECLARE_END, "}", 1]]
  end
  
  lex "Object{}" do
    [[:T_CONSTANT, "Object", 1],
     [:T_DECLARE_BEGIN, "{", 1],
     [:T_DECLARE_END, "}", 1]]
  end
  
  lex <<-code do
    Object {
      
    }
  code
    [[:T_CONSTANT, "Object", 1],
     [:T_DECLARE_BEGIN, "{", 1],
     [:T_DECLARE_END, "}", 3]]
  end
  
  lex <<-code do
    Object
    {
      
    }
  code
    [[:T_CONSTANT, "Object", 1],
     [:T_DECLARE_BEGIN, "{", 2],
     [:T_DECLARE_END, "}", 4]]
  end
    
end
