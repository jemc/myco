
require "bundler/gem_tasks"
require 'rspec/core/rake_task'


task :default => :test


file 'lib/myco/parser/peg_parser.rb' => 'lib/myco/parser/peg_parser.kpeg' do
  puts "Building PEG Parser..."
  raise "kpeg failed to build PEG Parser..." unless \
    system "kpeg -f lib/myco/parser/peg_parser.kpeg -s" \
               " -o lib/myco/parser/peg_parser.rb"
end


task :build_parser => 'lib/myco/parser/peg_parser.rb'
task :plinth => :build_parser

RSpec::Core::RakeTask.new :test_parser => :build_parser

task :test => :plinth do
  system "bin/myco spec/**/*.test.my spec/**/**/*.test.my"
end
