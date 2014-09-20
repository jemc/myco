
require 'spec_helper'


describe Myco::ToolSet::Parser, "Jumps" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    Object {
      foo: {
        77
        88 ->
        99
      }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :*], [:block,
        [:lit, 77], [:return, [:lit, 88]], [:lit, 99]
      ]]
    ]]
  end
  
end
