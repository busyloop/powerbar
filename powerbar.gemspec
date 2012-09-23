# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "powerbar/version"

Gem::Specification.new do |s|
  s.name        = "powerbar"
  s.version     = Powerbar::VERSION
  s.authors     = ["Moe"]
  s.email       = ["moe@busyloop.net"]
  s.homepage    = "https://github.com/busyloop/powerbar"
  s.summary = s.description = %q{The last progressbar-library you'll ever need}
  s.required_ruby_version = ">= 1.9.2"
  s.license     = "MIT"

  s.add_dependency "ansi", "~> 1.4.0"
  s.add_dependency "hashie", ">= 1.1.0"

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
end
