
require_relative 'myco/toolset'
require_relative 'myco/parser'
require_relative 'myco/compiler'
require_relative 'myco/eval'

require 'pp'

Lexer = Myco::ToolSet::Parser::Lexer

pp Lexer.new(<<"END_OF_MYCO").lex
  Object {
    foo: val
    bar: { val }
    
    Object {
      foo : val
      bar : { val }
      Object { }
    }
    
    Object { }
  }
END_OF_MYCO
