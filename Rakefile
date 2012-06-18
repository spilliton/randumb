# encoding: UTF-8

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rake/testtask'

task :default => [:test]

desc "Run unit tests."
task :test do
  ruby "test/randumb_test.rb"
  ruby "test/weighted_test.rb"
end