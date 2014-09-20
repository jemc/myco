
require 'spec_helper'


describe Myco::ToolSet::Parser, "Decorations" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    Object {
      on foo: null
      one two three: null
      four "five" six: null
      sym "str.ng": null
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo,   [:array, [:deco, :on]],
        [:args, :*], [:block, [:null]]],
      [:meme, :three, [:array, [:deco, :two], [:deco, :one]],
        [:args, :*], [:block, [:null]]],
      [:meme, :six, [:array, [:deco, :five], [:deco, :four]],
        [:args, :*], [:block, [:null]]],
      [:meme, :"str.ng", [:array, [:deco, :sym]],
        [:args, :*], [:block, [:null]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      on foo
      one two three
      four "five" six
      sym "str.ng"
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo,   [:array, [:deco, :on]],
        [:args, :*], [:null]],
      [:meme, :three, [:array, [:deco, :two], [:deco, :one]],
        [:args, :*], [:null]],
      [:meme, :six, [:array, [:deco, :five], [:deco, :four]],
        [:args, :*], [:null]],
      [:meme, :"str.ng", [:array, [:deco, :sym]],
        [:args, :*], [:null]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      on(true) foo
      one two(1,2,3) three: 88
      four("fore") "five" six
      sym(:bol) "str.ng": 99
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array,
        [:deco, :on, [:arglist, [:true]]]
      ], [:args, :*], [:null]],
      [:meme, :three, [:array,
        [:deco, :two, [:arglist, [:lit, 1], [:lit, 2], [:lit, 3]]],
        [:deco, :one]
      ], [:args, :*], [:block, [:lit, 88]]],
      [:meme, :six, [:array,
        [:deco, :five],
        [:deco, :four, [:arglist, [:lit, "fore"]]]
      ], [:args, :*], [:null]],
      [:meme, :"str.ng", [:array,
        [:deco, :sym, [:arglist, [:lit, :bol]]]
      ], [:args, :*], [:block, [:lit, 99]]]]]
  end
  
end
