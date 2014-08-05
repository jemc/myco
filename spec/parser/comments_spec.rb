
require 'spec_helper'


describe Myco::ToolSet::Parser, "Comments" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    # Toplevel comment
    Object {
      # In-component comment
      foo: {
        # In-meme comment
        88
      }
      bar: # Pre-meme-body comment
        99
      baz:
        # Pre-meme-body comment
        100
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args], [:block, [:lit, 88]]],
      [:meme, :bar, [:array], [:args], [:block, [:lit, 99]]],
      [:meme, :baz, [:array], [:args], [:block, [:lit, 100]]],
    ]]
  end
  
end
