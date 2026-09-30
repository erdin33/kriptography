require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

desc "Run the development server"
task :server do
  sh "bundle exec rackup -p 4567"
end

desc "Tahap 10: Run roundtrip test"
task :roundtrip => :fixtures do
  ruby "scripts/roundtrip.rb"
end

desc "Tahap 10: Generate fixtures"
task :fixtures do
  ruby "scripts/make_fixtures.rb"
end

task default: :test
