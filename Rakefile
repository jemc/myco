
task :default => :test

task :fetch_peg do
  url = "https://bitbucket.org/jemc/pegleromyces"
  dir = "lib/myco/code_tools/parser/pegleromyces"
  system "hg clone #{url} #{dir}" unless File.directory?(dir)
  system "cd #{dir} && hg pull -u"
  system "rm -rf #{dir}/spec" # Don't bother keeping specs in the subdir clone
end

task :plinth => :fetch_peg

task :test => :plinth do
  system "bin/myco spec/**/*.test.my spec/**/**/*.test.my"
end

task :release do
  puts("releasing...")
  system("rm -rf release") &&
  system("myco inoculate --verbose release") &&
  system("cd release && gem build ../myco.gemspec") &&
  system("cd release && gem install --no-rdoc --no-ri myco-*.gem") &&
  system("cd release && gem push myco-*.gem") &&
  puts("done releasing.")
end
