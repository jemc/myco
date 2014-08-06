
require 'rspec/its'
require 'timeout'
# require 'pry'
# require 'pry-rescue/rspec'

RSpec.configure do |c|
  # Enable 'should' syntax
  c.expect_with(:rspec) { |c| c.syntax = [:should, :expect] }
  c.mock_with(:rspec)   { |c| c.syntax = [:should, :expect] }
  
  # If any tests are marked with iso:true, only run those tests
  c.filter_run_including iso:true
  c.run_all_when_everything_filtered = true
  
  # Abort after first failure
  # (Use environment variable for developer preference)
  c.fail_fast = true if ENV['RSPEC_FAIL_FAST']
  
  # Set output formatter and enable color
  c.formatter = 'Fivemat'
  c.color     = true
end


require 'myco/toolset'
require 'myco/parser'
require 'myco/eval'
require 'myco/bootstrap'


require_relative 'helpers/parser_helper'
