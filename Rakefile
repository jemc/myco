
task :default => :sandbox

task :build_lexer do
  raise "Ragel railed to build Lexer..." unless \
    system "ragel -R myco/parser/lexer_skeleton.rl -o myco/parser/lexer.rb"
end

task :sandbox => :build_lexer do
  system "ruby ./sandbox.rb"
end
