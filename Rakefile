
require "bundler/gem_tasks"
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
task :build_parser => [:build_peg_parser]

task :plinth => :build_parser

RSpec::Core::RakeTask.new :test_parser => :build_parser

task :test => :plinth do
  system "bin/myco spec/**/*.test.my spec/**/**/*.test.my"
end

task :mycompile => :plinth do
  require_relative 'mycompile'
end

# Create the 'spore' directory, containing a pure-ruby implementation of Myco
# to be used to run Myco scripts or inoculate the self-hosted implementation.
task :spore => 'spore:all'
namespace :spore do
  task :all => [:my, :rb, :bin]
  
  task :bin => 'bin:all'
  namespace :bin do
    task :all => 'spore/bin/myco'
    
    file 'spore/bin/myco' => 'bin/myco' do
      system "mkdir -p spore && cp --parents bin/myco spore"
    end
  end
  
  task :rb => 'rb:all'
  namespace :rb do
    filenames = Dir.glob('lib/**/*.rb')
    spore = lambda { |filename| "spore/#{filename}" }
    
    task :all => filenames.map(&spore)
    
    filenames.each do |filename|
      file spore.(filename) => filename do
        system "mkdir -p spore && cp --parents #{filename} spore"
      end
    end
  end
  
  task :my => 'my:all'
  namespace :my do
    filenames = Dir.glob('lib/**/*.my')
    spore = lambda { |filename| "spore/#{filename}.rb" }
    
    task :all => filenames.map(&spore)
    
    filenames.each do |filename|
      file spore.(filename) => [filename, :plinth] do
        require_relative 'lib/myco'
        loader = Myco::CodeLoader::MycoLoader.new filename
        loader.emit_rb! spore.(filename)
      end
    end
  end
end
