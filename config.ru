current_path = File.expand_path(File.dirname(__FILE__))

adapter = ENV['ADAPTER'] || 'models'


require current_path + "/#{adapter}"
require 'rubygems'
require 'main'


run Main
