
require 'spec_helper'


describe Myco::ToolSet::Parser, "Constants" do
  extend SpecHelpers::ParserHelper
  
  lex "Object"   do [[:T_CONSTANT, "Object"]]  end.parse [:const, :Object]
  lex "OBJECT"   do [[:T_CONSTANT, "OBJECT"]]  end.parse [:const, :OBJECT]
  lex "Obj_3cT"  do [[:T_CONSTANT, "Obj_3cT"]] end.parse [:const, :Obj_3cT]
  lex "O"        do [[:T_CONSTANT, "O"]]       end.parse [:const, :O]
  
  lex "Obj::Ect::Ive" do
    [[:T_CONSTANT, "Obj"], [:T_SCOPE, "::"], [:T_CONSTANT, "Ect"],
                           [:T_SCOPE, "::"], [:T_CONSTANT, "Ive"]]
  end
  .parse [:colon2, [:colon2, [:const, :Obj], :Ect], :Ive]
  
  lex "::Toplevel::Object" do
    [[:T_SCOPE, "::"], [:T_CONSTANT, "Toplevel"],
     [:T_SCOPE, "::"], [:T_CONSTANT, "Object"]]
  end
  .parse [:colon2, [:colon3, :Toplevel], :Object]
  
end
