
require 'rspec/core/rake_task'


task :default => :test


RSpec::Core::RakeTask.new :test

task :build_lexer do
  raise "Ragel railed to build Lexer..." unless \
    system "ragel -R lib/myco/parser/lexer_skeleton.rl" \
                " -o lib/myco/parser/lexer.rb"
end

task :sandbox => :build_lexer do
  system "ruby ./sandbox.rb"
end
