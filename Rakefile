PROJECT_SUMMARY     = "Merb plugin that provides caching (page, action, fragment, object)"
PROJECT_DESCRIPTION = PROJECT_SUMMARY

GEM_AUTHORS = ["Ben Burkert", "Ben Schwarz", "Daniel Neighman"]

GEM_NAME    = "merb-cache"
PKG_BUILD   = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
GEM_VERSION = "1.0.0"

spec = Gem::Specification.new do |s|
  s.name = GEM_NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE", 'TODO']
  s.summary = PROJECT_SUMMARY
  s.description = PROJECT_DESCRIPTION
  s.authors = GEM_AUTHORS
  s.add_dependency('merb-core', ">= 1.0")
  s.require_path = 'lib'
  s.files = %w(LICENSE README Rakefile TODO) + Dir.glob("{lib,spec}/**/*")
end

require 'rake'
require 'spec/rake/spectask'

desc "Run all examples (or a specific spec with TASK=xxxx)"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_opts  = ["-cfs"]
  t.spec_files = begin
    if ENV["TASK"] 
      ENV["TASK"].split(',').map { |task| "spec/**/#{task}_spec.rb" }
    else
      FileList['spec/**/*_spec.rb']
    end
  end
end

desc 'Default: run spec examples'
task :default => 'spec'