# encoding: UTF-8

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rake/testtask'

task :default => [:test_units]

desc "Run basic tests"
Rake::TestTask.new("test_units") do |t|
  t.pattern = 'test/randumb_test.rb'
  t.verbose = true
  t.warning = true
end