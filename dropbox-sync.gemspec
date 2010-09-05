# -*- encoding: utf-8 -*-
require File.expand_path("../lib/dropbox_sync/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "dropbox-sync"
  s.version     = DropboxSync::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Willem van Bergen']
  s.email       = ['willem@railsdoctors.com']
  s.homepage    = "http://github.com/wvanbergen/dropbox-sync"
  s.summary     = "Tool to synchronize folders between machiens using Dropbox and symbolic links."
  s.description = <<-D
    This tool will create symbolic links in the Dropbox folder to synchronize paths outside of it. This
    will cause Dropbox to synchronize the content with your Dropbox account. This tool can then be used
    on a different machine (with the same Dropbox account) to recreate the symbolic links and setup
    synchronization between your machines.
  D

  s.required_rubygems_version = ">= 1.3.6"

  s.add_runtime_dependency     "thor"
  s.add_development_dependency "bundler", ">= 1.0.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
