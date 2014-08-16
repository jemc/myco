
require 'spec_helper'


describe Myco::ToolSet::Parser, "Categories" do
  extend SpecHelpers::ParserHelper
  
  parse <<-'code' do
    [foo]
  code
    [:category, :"foo"]
  end
  
  parse <<-'code' do
    [foo\[bar\]baz]
  code
    [:category, :"foo[bar]baz"]
  end
  
end
