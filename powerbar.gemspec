# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "powerbar/version"

Gem::Specification.new do |s|
  s.name        = "powerbar"
  s.version     = Powerbar::VERSION
  s.authors     = ["Moe"]
  s.email       = ["moe@busyloop.net"]
  s.homepage    = "https://github.com/busyloop/powerbar"
  s.summary     = %q{The last progressbar-library you'll ever need}
  s.description = %q{The last progressbar-library you'll ever need}
  s.license     = "MIT"

  s.add_dependency "hashie", ">= 1.1.0"

  s.files         = `git ls-files`.split("\n").reject {|e| e.start_with? 'ass/'}
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
