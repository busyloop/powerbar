# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "powerbar/version"

Gem::Specification.new do |s|
  s.name        = "powerbar"
  s.version     = Powerbar::VERSION
  s.authors     = ["Moe"]
  s.email       = ["moe@busyloop.net"]
  s.homepage    = "https://github.com/busyloop/powerbar"
  s.summary     = %q{The last progressbar-library you'll ever need}
  s.description = %q{The last progressbar-library you'll ever need}
  s.required_ruby_version = ">= 1.9.2"

  s.add_dependency "ansi", "~> 1.4.0"
  s.add_dependency "hashie", ">= 1.1.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
