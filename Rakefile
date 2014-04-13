
task :default => :sandbox

task :build_lexer do
  raise "Ragel railed to build Lexer..." unless \
    system "ragel -R myco/parser/lexer.rl"
end

task :sandbox => :build_lexer do
  system "ruby ./sandbox.rb"
end
