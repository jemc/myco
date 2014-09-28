
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
  .to_ruby <<-'RUBY'
    (__c__ = ::Myco::Component.new([
      ::Myco.find_constant(:Object)
    ], self, __FILE__, __LINE__)
    __c__.__last__ = __c__.module_eval {(
      declare_meme(:foo, [
        [:on, [
          true
        ]]
      ]) { |*| nil}
      declare_meme(:three, [
        [:two, [
          1,
          2,
          3
        ]],
        [:one, []]
      ]) { |*| (
        88
      )}
      declare_meme(:six, [
        [:five, []],
        [:four, [
          "fore"
        ]]
      ]) { |*| nil}
      declare_meme(:"str.ng", [
        [:sym, [
          :bol
        ]]
      ]) { |*| (
        99
      )}
    )}
    __c__.instance)
  RUBY
  
end
