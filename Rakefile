
require 'rspec/core/rake_task'


task :default => :test


task :build_lexer do
  raise "Ragel failed to build Lexer..." unless \
    system "ragel -R lib/myco/parser/lexer_skeleton.rl" \
                " -o lib/myco/parser/lexer.rb"
end

task :build_builder do
  raise "Racc failed to build Builder..." unless \
    system "racc -t lib/myco/parser/builder.racc -v" \
               " -o lib/myco/parser/builder.rb"
  
  # Reopen file to fix racc problem with class in constant hierarchy
  File.read("lib/myco/parser/builder.rb").tap do |buffer|
    File.open("lib/myco/parser/builder.rb", "w") do |file|
      file.write buffer.gsub('MycoBuilder', 'Myco::ToolSet::Parser::Builder')
    end
  end
end

task :build => [:build_lexer, :build_builder]


RSpec::Core::RakeTask.new :test => :build

task :sandbox => :build do
  system "ruby ./sandbox.rb"
end
