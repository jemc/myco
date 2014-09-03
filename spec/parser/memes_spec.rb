
require 'spec_helper'


describe Myco::ToolSet::Parser, "Memes" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    Object {
      foo:    one
      bar  :  Two  
      baz    :3
      deci  : 3.88
      ary :  [1,2, 3,
              4
              5,,
              6
              
              7,
             ]
      all:null
      none:void
      str  : "string"
      sym  :  :bol
      ssym : :"with spaces"
      s  :  self
      t:    true
      f:    false
      "x y" : z
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block, 
      [:meme, :foo,   [:array], [:args], [:block, [:lambig, :one]]],
      [:meme, :bar,   [:array], [:args], [:block, [:const, :Two]]],
      [:meme, :baz,   [:array], [:args], [:block, [:lit, 3]]],
      [:meme, :deci,  [:array], [:args], [:block, [:lit, 3.88]]],
      [:meme, :ary,   [:array], [:args], [:block, [:array,
        [:lit, 1], [:lit, 2], [:lit, 3], [:lit, 4],
        [:lit, 5], [:lit, 6], [:lit, 7]]]],
      [:meme, :all,   [:array], [:args], [:block, [:null]]],
      [:meme, :none,  [:array], [:args], [:block, [:void]]],
      [:meme, :str,   [:array], [:args], [:block, [:lit, "string"]]],
      [:meme, :sym,   [:array], [:args], [:block, [:lit, :bol]]],
      [:meme, :ssym,  [:array], [:args], [:block, [:lit, :"with spaces"]]],
      [:meme, :s,     [:array], [:args], [:block, [:self]]],
      [:meme, :t,     [:array], [:args], [:block, [:true]]],
      [:meme, :f,     [:array], [:args], [:block, [:false]]],
      [:meme, :"x y", [:array], [:args], [:block, [:lambig, :z]]],
    ]]
  end
  
  parse <<-'code' do
    Object {
      a: 1 + 2 * 3
      b: 1 / 2 - 3
      x: a . b % 3
      y: a ** b <=> x
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :a, [:array], [:args], [:block,
        [:call, [:lit, 1], :+, [:arglist,
                [:call, [:lit, 2], :*, [:arglist, [:lit, 3]]]]]
      ]],
      [:meme, :b, [:array], [:args], [:block,
        [:call, [:call, [:lit, 1], :/, [:arglist, [:lit, 2]]], 
                :-, [:arglist, [:lit, 3]]]
      ]],
      [:meme, :x, [:array], [:args], [:block,
        [:call, [:call, [:lambig, :a], :b, [:arglist]],
                :%, [:arglist, [:lit, 3]]]
      ]],
      [:meme, :y, [:array], [:args], [:block,
        [:call, [:call, [:lambig, :a], :**, [:arglist, [:lambig, :b]]], 
                :<=>, [:arglist, [:lambig, :x]]]
      ]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo:  {  one  }
      bar  :{  Two  }
      baz    :{3}  
      all:{null }
      else: { "what" }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args], [:block, [:lambig, :one]]],
      [:meme, :bar, [:array], [:args], [:block, [:const, :Two]]],
      [:meme, :baz, [:array], [:args], [:block, [:lit, 3]]],
      [:meme, :all, [:array], [:args], [:block, [:null]]],
      [:meme, :else, [:array], [:args], [:block, [:lit, "what"]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: {
        one
      }
      bar:{ Two
        }
      baz  :{
        3}
      all: \
        null
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args], [:block, [:lambig, :one]]],
      [:meme, :bar, [:array], [:args], [:block, [:const, :Two]]],
      [:meme, :baz, [:array], [:args], [:block, [:lit, 3]]],
      [:meme, :all, [:array], [:args], [:block, [:null]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo:  |a|one
      bar  :  ||  Two  
      baz    :|c,d,*e|  3
      all:
      |a|
      null
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :a], [:block, [:lambig, :one]]],
      [:meme, :bar, [:array], [:args], [:block, [:const, :Two]]],
      [:meme, :baz, [:array], [:args, :c, :d, :"*e"], [:block, [:lit, 3]]],
      [:meme, :all, [:array], [:args, :a], [:block, [:null]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo:  |a|{one}
      bar  :  ||{  Two  }
      baz    :|c,d,*e|  {  3
      }
      all:
      |a|
      {
        null
      }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :a], [:block, [:lambig, :one]]],
      [:meme, :bar, [:array], [:args], [:block, [:const, :Two]]],
      [:meme, :baz, [:array], [:args, :c, :d, :"*e"], [:block, [:lit, 3]]],
      [:meme, :all, [:array], [:args, :a], [:block, [:null]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: { func() }
      bar: { func(1,2,null) }
      baz: {
        func(
          1,
          2,
          null
        )
      }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist]]]],
      [:meme, :bar, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:null]]]]],
      [:meme, :baz, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:null]]]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: func()
      bar: func(1,2,null)
      baz:
      func(
        1,
        2,
        null
      )
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist]]]],
      [:meme, :bar, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:null]]]]],
      [:meme, :baz, [:array], [:args], [:block,
        [:call, [:self], :func, [:arglist, [:lit, 1], [:lit, 2], [:null]]]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: obj.func
      bar: obj.other.func(1,2,null).other(5,6)
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args], [:block,
        [:call, [:lambig, :obj], :func, [:arglist]]]],
      [:meme, :bar, [:array], [:args], [:block,
        [:call,
          [:call,
            [:call, [:lambig, :obj], :other, [:arglist]],
             :func, [:arglist, [:lit, 1], [:lit, 2], [:null]]],
           :other, [:arglist, [:lit, 5], [:lit, 6]]]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: x = 8
      bar: a.b = foo
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args], [:block, [:lasgn, :x, [:lit, 8]]]],
      [:meme, :bar, [:array], [:args], [:block,
        [:call, [:lambig, :a], :b=, [:arglist, [:lambig, :foo]]]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: |a,b, c,
        d
        e,,
        f
        
        g,
      | { }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :a, :b, :c, :d, :e, :f, :g], [:null]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: |a,b,
            c=0,,
            d = 5
            | { }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :a, :b, :c, :d, [:block,
        [:lasgn, :c, [:lit, 0]],
        [:lasgn, :d, [:lit, 5]]
      ]],
      [:null]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: |*a, &b| bar(*a, &b)
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args, :"*a", :"&b"], [:block,
        [:call, [:self], :bar, [:arglist,
          [:splat, [:lambig, :a]], [:block_pass, [:lambig, :b]]
        ]]
      ]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: Object { }
      bar: o = Object { }
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args], [:block,
        [:declobj, [:array, [:const, :Object]], [:null]]]],
      [:meme, :bar, [:array], [:args], [:block,
        [:lasgn, :o, [:declobj, [:array, [:const, :Object]], [:null]]]]]
    ]]
  end
  
  parse <<-'code' do
    Object {
      foo: a = 88
      bar: a(99, 101) = 88
      baz: a.b(99, 101) = 88
    }
  code
    [:declobj, [:array, [:const, :Object]], [:block,
      [:meme, :foo, [:array], [:args], [:block,
        [:lasgn, :a, [:lit, 88]]]],
      [:meme, :bar, [:array], [:args], [:block,
        [:call, [:self], :a=, [:arglist,
          [:lit, 88], [:lit, 99], [:lit, 101]]]]],
      [:meme, :baz, [:array], [:args], [:block,
        [:call, [:lambig, :a], :b=, [:arglist,
          [:lit, 88], [:lit, 99], [:lit, 101]]]]],
    ]]
  end
  
end
