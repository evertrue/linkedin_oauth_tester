#!/usr/bin/env rake

task :test do
  require './linkedin_test'

  test = LinkedInTest.new
  test.execute
  test.close
end

task :server do
  system 'rackup'
end
