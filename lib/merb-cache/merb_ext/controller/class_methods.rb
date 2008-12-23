module Merb::Cache::Controller
  module ClassMethods
    def self.extended(base)
      base.send :class_inheritable_accessor, :_cache
      base._cache = {}
    end
    
    
    def cache!(conditions = {})
      before(:_cache_before, conditions.only(:if, :unless).merge(:with => conditions))
      after(:_cache_after, conditions.only(:if, :unless).merge(:with => conditions))
    end

    # cache is an alias to cache_action, it will take multiple :actions and pass the conditions hash for each action
    #
    # @param *actions<Array[Symbol]> actions to cache
    #
    # @param options<Hash> Conditions passed to the store and two options specific to cache
    # 
    # @note
    #   Specific options for cache:
    #     - :store (or :stores) use the specified store
    #     - :params list of params to pass to the store (see _parameters_and_conditions)
    #
    # @example cache :index, :show, :expire_in => 30 # caches the index and show action for 30 seconds
    # @example cache :index, :store => :page_store   # caches the index action using the page store
    # @example cache :index, :params => [:page, :q], :store => :action_store # caches the index action using the action store and passing the :page and :q params to the action store (NB. :params => <Array> has no effect on the page store)
    #
    # @api public
    def cache(*actions)
      options = extract_options_from_args!(actions) || {}
      actions.each {|a| cache_action(a, options)}
    end
    
    # cache action will cache the action
    # Parameters are the same as cache but only one action is allowed
    #
    # @api private
    def cache_action(action, conditions = {})
      self._cache[action] = conditions
      before("_cache_#{action}_before", conditions.only(:if, :unless).merge(:with => [conditions], :only => action))
      after("_cache_#{action}_after", conditions.only(:if, :unless).merge(:with => [conditions], :only => action))
      alias_method "_cache_#{action}_before", :_cache_before
      alias_method "_cache_#{action}_after",  :_cache_after
    end
  
    # Checks if the action called with a certain request would be cached or not. Usefull for troubleshooting problems
    #
    # @param action<String> action to check
    # 
    # @param request_hash<Hash> The params that the request would have. :uri and :method are also supported to indicate the :uri and :method of the request. :store and :stores indicate the cache store to use.
    #
    # @note
    #   if not specified, the default http method is :get and the default uri is '/'
    #
    # @return <TrueClass, FalseClass>
    #   True if such a request would be cached
    #
    # @example Project.caches? :index, :uri => '/projects', :params => {:q => 'test'}, :method => :get
    # @example Project.caches? :show, :uri => url(:project, @project), :params => {:id => @project.id}
    #
    # @api public
    def caches?(action, params = {})
      controller, conditions = _controller_and_conditions(action, params)
      Merb::Cache[controller._lookup_store(conditions)].writable?(controller, *controller._parameters_and_conditions(conditions))
    end
    
    # Checks if the action called with a certain request has been cached or not.
    #
    # @param action<String> action to check
    # 
    # @param request_hash<Hash> The params that the request would have. :uri and :method are also supported to indicate the :uri and :method of the request. :store and :stores indicate the cache store to use.
    #
    # @note
    #   if not specified, the default http method is :get and the default uri is '/'
    #
    # @return <TrueClass, FalseClass>
    #   True if such a request has been cached
    #
    # @example Project.caches? :index, :uri => '/projects', :params => {:q => 'test'}, :method => :get
    #
    # @api public    
    def cached?(action, params = {})
      controller, conditions = _controller_and_conditions(action, params)
      Merb::Cache[controller._lookup_store(conditions)].exists?(controller, *controller._parameters_and_conditions(conditions))
    end

    # Returns the cache for the action with the given request
    #
    # @param action<String> action to check
    # 
    # @param request_hash<Hash> The params that the request would have. :uri and :method are also supported to indicate the :uri and :method of the request. :store and :stores indicate the cache store to use.
    #
    # @note
    #   if not specified, the default http method is :get and the default uri is '/'
    #
    # @return <Object>
    #   The content of the cache if available, else nil
    #
    # @example Project.cache_for :index, :uri => '/projects', :params => {:q => 'test'}, :method => :get
    #
    # @api public  
    def cache_for(action, params = {})
      controller, conditions = _controller_and_conditions(action, params)
      Merb::Cache[controller._lookup_store(conditions)].read(controller, *controller._parameters_and_conditions(conditions).first)      
    end
    
    # Deletes the cache for the action with the given request
    #
    # @param action<String> action
    # 
    # @param request_hash<Hash> The params that the request would have. :uri and :method are also supported to indicate the :uri and :method of the request. :store and :stores indicate the cache store to use.
    #
    # @note
    #   if not specified, the default http method is :get and the default uri is '/'
    #
    #
    # @example Project.delete_cache_for :index, :uri => '/projects', :params => {:q => 'test'}, :method => :get
    #
    # @api public
    def delete_cache_for(action, params = {})
      controller, conditions = _controller_and_conditions(action, params)
      Merb::Cache[controller._lookup_store(conditions)].delete(controller, *controller._parameters_and_conditions(conditions).first)      
    end
  
    # Caches specified with eager_cache will be run after #trigger_action has been run
    # without holding some poor user up generating the cache (through run_later)
    # 
    # @param trigger_action<Symbol, Array[*Symbol]> The actions that will trigger the eager caching
    # @param target<Array[Controller,Symbol], Symbol> the target option to cache (if no controller is given, the current controller is used)
    # @param conditions<Hash> conditions passed to the store. See note for conditions specific to eager_cache
    # @param blk<Block> Block run to generate the request or controller used for eager caching after trigger_action has run
    #
    # @note
    #   There are a number of options specific to eager_cache in the conditions hash
    #     - :uri the uri of the resource you want to eager cache (needed by the page store but can be provided instead by a block)
    #     - :method http method used (defaults to :get)
    #     - :store which store to use
    #     - :params list of params to pass to the store when writing to it
    #
    # @example eager_cache :update, :index, :uri => '/articles' # When the update action is completed, a get request to :index with '/articles' uri will be cached (if you use the page store, this will be stored in '/articles.html')
    # @example eager_cache :create, :index # Same after the create action but since no uri is given, the current uri is used with the default http method (:get). Useful default for resource controllers
    # @example eager_cache(:create, [Timeline, :index]) {{ :uri => build_url(:timelines)}} 
    #
    # @api public
    def eager_cache(trigger_actions, target = nil, conditions = {}, &blk)
      trigger_actions = [*trigger_actions]
      target, conditions = nil, target if target.is_a? Hash
  
      trigger_actions.each do |trigger_action|

        if target.is_a? Array
          target_controller, target_action = *target
        else
          target_controller, target_action = self, (target || trigger_action)
        end

        after("_eager_cache_#{trigger_action}_to_#{target_controller.name.snake_case}__#{target_action}_after", conditions.only(:if, :unless).merge(:with => [target_controller, target_action, conditions, blk], :only => trigger_action))
        alias_method "_eager_cache_#{trigger_action}_to_#{target_controller.name.snake_case}__#{target_action}_after", :_eager_cache_after
      end
    end
  
    # Dispatches eager caches to a worker process
    #
    # @param action<String> The actiont to dispatch
    # @param params<Hash> params of the request (passed to the block)
    # @param env<Hash> environment variables of the request (passed to the block)
    # @param blk<Block> block used to build the request (should return a hash, request or a controller)
    #
    # @api private
    def eager_dispatch(action, params = {}, env = {}, blk = nil)
      kontroller = if blk.nil?
        new(build_request(env))
      else
        result = case blk.arity
          when 0  then  blk[]
          when 1  then  blk[params]
          else          blk[*[params, env]]
        end

        case result
        when NilClass         then new(build_request(env))
        when Hash, Mash       then new(build_request(result))
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
    #
    # @param request_hash<Hash> hash used to describe the request
    #
    # @note Acceptable options for the request hash
    #   - :uri The uri of the request
    #   - :method The http method (defaults to :get)
    #   - :params The params
    #   - any env variable you may need
    #
    # @return <Request>
    #   A request for the given arguments
    #
    # @example build_request(:params => {:id => @article.id}, :method => :put, :uri => build_url(:article, @article)}) # a request corresponding to the update action of a resourceful controller
    #
    # @api public
    def build_request(request_hash = {})
      Merb::Cache::CacheRequest.new(request_hash.delete(:uri), request_hash.delete(:params), request_hash)
    end

    # @see Router.url
    def build_url(*args)
      Merb::Router.url(*args)
    end
    
    # Used by cache?, cached?, cache_for and delete_cache_for to generate the controller from the given parameters.
    #
    # @param action<String> the cached action
    # @param request_hash<Hash> params from the request.
    #
    # @note
    #   in the request hash, :params, :uri and :method are supported. Additionally :store and :stores specify which store to use. 
    #
    # @return <Array[Controller, Hash]>
    #   the controller built using the request corresponding to params
    #   the conditions for the cached action
    #
    # @api private
    def _controller_and_conditions(action, request_hash)
      conditions = self._cache[action]
      conditions.merge!(request_hash.only(:store, :stores))
      request_hash.extract!(:store, :stores)
      controller = new(build_request(request_hash))
      controller.action_name = action

      [controller, conditions]
    end
  end
end