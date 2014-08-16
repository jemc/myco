
require 'rspec/core/rake_task'


task :default => :test


file 'lib/myco/parser/lexer.rb' => 'lib/myco/parser/lexer.rl' do
  puts "Building Lexer..."
  raise "Ragel failed to build Lexer..." unless \
    system "ragel -R lib/myco/parser/lexer_skeleton.rl" \
                " -o lib/myco/parser/lexer.rb"
end

file 'lib/myco/parser/builder.rb' => 'lib/myco/parser/builder.racc' do
  puts "Building Builder..."
  print "\033[1;31m" # Use bold red text color in terminal for Racc warnings
  
  raise "Racc failed to build Builder..." unless \
    system "racc -t lib/myco/parser/builder.racc -v" \
               " -o lib/myco/parser/builder.rb"
  
  print "\033[0m" # End terminal coloring
end

file 'lib/myco/parser/peg_parser.rb' => 'lib/myco/parser/peg_parser.kpeg' do
  puts "Building PEG Parser..."
  raise "kpeg failed to build PEG Parser..." unless \
    system "kpeg -f lib/myco/parser/peg_parser.kpeg -s" \
               " -o lib/myco/parser/peg_parser.rb"
end


task :build_lexer => 'lib/myco/parser/lexer.rb'
task :build_builder => 'lib/myco/parser/builder.rb'
task :build_peg_parser => 'lib/myco/parser/peg_parser.rb'
task :build => [:build_peg_parser]


RSpec::Core::RakeTask.new :test => :build do |t|
  test_group = 'strings'
  t.pattern = "spec/**/#{test_group}_spec.rb"
end

task :sandbox => :build do
  require_relative 'sandbox.rb'
end
