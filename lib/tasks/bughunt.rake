namespace :bughunt do
  desc "Run Oracle validation tests"
  task :oracles do
    ruby "-Ilib", "test/oracles/oracle_test.rb"
  end

  desc "Run RED failing tests"
  task :red do
    Dir.glob("test/bughunt/pending/*_test.rb").each do |file|
      ruby "-Ilib", file
    end
  end

  desc "Run all bughunt tests"
  task :all => [:oracles, :red]
end
