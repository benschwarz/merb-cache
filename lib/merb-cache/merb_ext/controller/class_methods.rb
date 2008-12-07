module Merb::Cache::Controller
  module ClassMethods
    def cache!(conditions = {})
      before(:_cache_before, conditions.only(:if, :unless).merge(:with => conditions))
      after(:_cache_after, conditions.only(:if, :unless).merge(:with => conditions))
    end

    # cache is an alias to cache_action, it will take multiple :actions 
    # eg: cache :index, :show
    # no options can be sent to this method
    def cache(*actions)
      if actions.last.is_a? Hash
        cache_action(*actions)
      else
        actions.each {|a| cache_action(*a)}
      end
    end

    # cache action will perform an action_cache
    # valid options are:
    # :expire_in => 3600 (one hour)
    def cache_action(action, conditions = {})
      before("_cache_#{action}_before", conditions.only(:if, :unless).merge(:with => [conditions], :only => action))
      after("_cache_#{action}_after", conditions.only(:if, :unless).merge(:with => [conditions], :only => action))
      alias_method "_cache_#{action}_before", :_cache_before
      alias_method "_cache_#{action}_after",  :_cache_after
    end
  
    # Caches specified with eager_cache will be run after #trigger_action has been run
    # For example
    # eager_cache :index, :show
    # :show will be re-cached outside the user request cycle after the :index
    # action has been executed.
    def eager_cache(trigger_action, target = trigger_action, conditions = {}, &blk)
      target, conditions = trigger_action, target if target.is_a? Hash

      if target.is_a? Array
        target_controller, target_action = *target
      else
        target_controller, target_action = self, target
      end

      after("_eager_cache_#{trigger_action}_to_#{target_controller.name.snake_case}__#{target_action}_after", conditions.only(:if, :unless).merge(:with => [target_controller, target_action, conditions, blk], :only => trigger_action))
      alias_method "_eager_cache_#{trigger_action}_to_#{target_controller.name.snake_case}__#{target_action}_after", :_eager_cache_after
    end
  
    # Dispatches eager caches to a worker process
    def eager_dispatch(action, params = {}, env = {}, blk = nil)
      kontroller = if blk.nil?
        new(Merb::Request.new(env))
      else
        result = case blk.arity
          when 0  then  blk[]
          when 1  then  blk[params]
          else          blk[*[params, env]]
        end

        case result
        when NilClass         then new(Merb::Request.new(env))
        when Hash, Mash       then new(Merb::Request.new(result))
        when Merb::Request    then new(result)
        when Merb::Controller then result
        else raise ArgumentError, "Block to eager_cache must return nil, the env Hash, a Request object, or a Controller object"
        end
      end

      kontroller.force_cache!

      kontroller._dispatch(action)

      kontroller
    end
  
    # Builds a request that will be sent to the merb worker process to be
    # cached without holding some poor user up generating the cache (through run_later)
    def build_request(path, params = {}, env = {})
      path, params, env = nil, path, params if path.is_a? Hash

      Merb::Cache::CacheRequest.new(path, params, env)
    end

    def build_url(*args)
      Merb::Router.url(*args)
    end
  end
end