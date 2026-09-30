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
task :roundtrip do
  puts "belum diimplementasikan"
end

desc "Tahap 10: Generate fixtures"
task :fixtures do
  puts "belum diimplementasikan"
end

task default: :test
