PROJECT_SUMMARY     = "Merb plugin that provides caching (page, action, fragment, object)"
PROJECT_DESCRIPTION = PROJECT_SUMMARY
PKG_BUILD   = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''

Gem::Specification.new do |s|
  s.name = "merb-cache"
  s.version = '1.0.0'
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.summary = PROJECT_SUMMARY
  s.description = PROJECT_DESCRIPTION
  s.authors = ["Ben Burkert", "Ben Schwarz", "Daniel Neighman"]
  s.add_dependency('merb-core', ">= 1.0")
  s.require_path = 'lib'
  s.files = %w(LICENSE README Rakefile) + Dir.glob("{lib,spec}/**/*")
end