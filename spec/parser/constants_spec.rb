
require 'spec_helper'


describe Myco::ToolSet::Parser, "Constants" do
  extend SpecHelpers::ParserHelper
  
  lex "Object"  do [[:T_CONSTANT, "Object",  1]] end.parse [:const, :Object]
  lex "OBJECT"  do [[:T_CONSTANT, "OBJECT",  1]] end.parse [:const, :OBJECT]
  lex "Obj_3cT" do [[:T_CONSTANT, "Obj_3cT", 1]] end.parse [:const, :Obj_3cT]
  lex "O"       do [[:T_CONSTANT, "O",       1]] end.parse [:const, :O]
  
end
