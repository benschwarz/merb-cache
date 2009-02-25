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
  s.authors = ["Ben Burkert", "Ben Schwarz", "Daniel Neighman", "Guillaume Maury"]
  s.add_dependency('merb-core', ">= 1.0")
  s.require_path = 'lib'
  s.files = %w(LICENSE README Rakefile lib/merb-cache
  lib/merb-cache/cache.rb
  lib/merb-cache/cache_request.rb
  lib/merb-cache/core_ext
  lib/merb-cache/core_ext/enumerable.rb
  lib/merb-cache/core_ext/hash.rb
  lib/merb-cache/merb_ext
  lib/merb-cache/merb_ext/controller
  lib/merb-cache/merb_ext/controller/class_methods.rb
  lib/merb-cache/merb_ext/controller/instance_methods.rb
  lib/merb-cache/stores
  lib/merb-cache/stores/fundamental
  lib/merb-cache/stores/fundamental/abstract_store.rb
  lib/merb-cache/stores/fundamental/file_store.rb
  lib/merb-cache/stores/fundamental/memcached_store.rb
  lib/merb-cache/stores/strategy
  lib/merb-cache/stores/strategy/abstract_strategy_store.rb
  lib/merb-cache/stores/strategy/action_store.rb
  lib/merb-cache/stores/strategy/adhoc_store.rb
  lib/merb-cache/stores/strategy/gzip_store.rb
  lib/merb-cache/stores/strategy/mintcache_store.rb
  lib/merb-cache/stores/strategy/page_store.rb
  lib/merb-cache/stores/strategy/sha1_store.rb
  lib/merb-cache.rb
  spec/merb-cache
  spec/merb-cache/cache_request_spec.rb
  spec/merb-cache/cache_spec.rb
  spec/merb-cache/core_ext
  spec/merb-cache/core_ext/enumerable_spec.rb
  spec/merb-cache/core_ext/hash_spec.rb
  spec/merb-cache/merb_ext
  spec/merb-cache/merb_ext/controller_spec.rb
  spec/merb-cache/stores
  spec/merb-cache/stores/fundamental
  spec/merb-cache/stores/fundamental/abstract_store_spec.rb
  spec/merb-cache/stores/fundamental/file_store_spec.rb
  spec/merb-cache/stores/fundamental/memcached_store_spec.rb
  spec/merb-cache/stores/strategy
  spec/merb-cache/stores/strategy/abstract_strategy_store_spec.rb
  spec/merb-cache/stores/strategy/action_store_spec.rb
  spec/merb-cache/stores/strategy/adhoc_store_spec.rb
  spec/merb-cache/stores/strategy/gzip_store_spec.rb
  spec/merb-cache/stores/strategy/mintcache_store_spec.rb
  spec/merb-cache/stores/strategy/page_store_spec.rb
  spec/merb-cache/stores/strategy/sha1_store_spec.rb
  spec/spec_helper.rb)
end