# make sure we're running inside Merb
if defined?(Merb::Plugins)
  require "merb-cache" / "cache"
  require "merb-cache" / "core_ext" / "enumerable"
  require "merb-cache" / "core_ext" / "hash"
  require "merb-cache" / "merb_ext" / "controller" / "class_methods"
  require "merb-cache" / "merb_ext" / "controller" / "instance_methods"
  require "merb-cache" / "cache_request"

  class Merb::Controller 
    extend Merb::Cache::Controller::ClassMethods
  end
  
  Merb::Controller.send(:include, Merb::Cache::Controller::InstanceMethods)
end
