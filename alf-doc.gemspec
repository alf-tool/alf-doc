$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require "alf/doc/version"
$version = Alf::Doc::Version.to_s

Gem::Specification.new do |s|
  s.name = "alf-doc"
  s.version = $version
  s.summary = "Documentation of Alf relational algebra"
  s.description = "This gem provides support for using the formal documentation of Alf."
  s.homepage = "http://github.com/blambeau/alf"
  s.authors = ["Bernard Lambeau"]
  s.email  = ["blambeau at gmail.com"]
  s.require_paths = ['lib']
  here = File.expand_path(File.dirname(__FILE__))
  s.files = File.readlines(File.join(here, 'Manifest.txt')).
                 inject([]){|files, pattern| files + Dir[File.join(here, pattern.strip)]}.
                 collect{|x| x[(1+here.size)..-1]}


  s.add_development_dependency("wlang", "~> 2.1")
  s.add_development_dependency("redcarpet", "~> 3.0")
  s.add_development_dependency("albino", "~> 1.3")
  s.add_development_dependency("md2man", "~> 2.0")
  s.add_development_dependency("rake", "~> 10.0")
  s.add_development_dependency("rspec", "~> 2.12")
  s.add_dependency("alf-core", "0.16.1")

end
