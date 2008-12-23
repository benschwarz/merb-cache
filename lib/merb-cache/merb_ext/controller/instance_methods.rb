module Merb::Cache::Controller
  module InstanceMethods
    # Partial / fragment caches are written / retrieved using fetch_partial
    #
    # @params template<String, Symbol> The path to the template, relative to the current controller or the template root
    # @params opts<Hash> Options for the partial (@see Merb::RenderMixin#partial)
    # @params conditions<Hash> conditions for the store (also accept :store for specifying the store)
    #
    # @note
    #   The opts hash supports :params_for_cache which can be used to specify which parameters will be passed to the store.
    #   If you call `fetch_partial` with parameters that are instance of model it will fail, so you need to use :params_for_cache in this case
    #
    # @example fetch_partial :bar
    # @example fetch_partial :foo, :with => @foo, :params_for_cache => {:foo => @foo.id}
    # @example fetch_partial :store, :with => @items, :params_for_cache => {:store_version => @store.version, :store_id => @store.id} 
    def fetch_partial(template, opts={}, conditions = {})
      template_id = template.to_s
      if template_id =~ %r{^/}
        template_path = File.dirname(template_id) / "_#{File.basename(template_id)}"
      else
        kontroller = (m = template_id.match(/.*(?=\/)/)) ? m[0] : controller_name
        template_id = "_#{File.basename(template_id)}"
      end

      unused, template_key = _template_for(template_id, opts.delete(:format) || content_type, kontroller, template_path)
      template_key.gsub!(File.expand_path(Merb.root),'')

      fetch_proc = lambda { partial(template, opts) }
      params_for_cache = opts.delete(:params_for_cache) || opts.dup

      concat(Merb::Cache[_lookup_store(conditions)].fetch(template_key, params_for_cache, conditions, &fetch_proc), fetch_proc.binding)
    end



    # Used to cache the result of a long running block
    #
    # @params opts<Hash> options (only uses :cache_key to define the key used)
    # @params conditions<Hash> conditions passed to the store (also accept :store for specifying the store)
    # @params &proc<Block> block generating the result to cache
    #
    # @example fetch_fragment { #stuff to do}
    #
    # @api public
    def fetch_fragment(opts = {}, conditions = {}, &proc)
      if opts[:cache_key].blank?
        file, line = proc.to_s.scan(%r{^#<Proc:0x\w+@(.+):(\d+)>$}).first
        fragment_key = "#{file}[#{line}]"
      else
        fragment_key = opts.delete(:cache_key)
      end
      
      concat(Merb::Cache[_lookup_store(conditions)].fetch(fragment_key, opts, conditions) { capture(&proc) }, proc.binding)
    end

    def _cache_before(conditions = {})
      unless @_force_cache
        if @_skip_cache.nil? && data = Merb::Cache[_lookup_store(conditions)].read(self, _parameters_and_conditions(conditions).first)
          throw(:halt, data)
          @_cached = true
        else
          @_cached = false
        end
      end
    end

    def _cache_after(conditions = {})
      if @_cached == false
        if Merb::Cache[_lookup_store(conditions)].write(self, nil, *_parameters_and_conditions(conditions))
          @_cache_write = true
        end
      end
    end

    def _eager_cache_after(klass, action, options = {}, blk = nil)
      unless @skip_cache
        run_later do
          env = request.env.dup
          env.merge!(options.only(:method, :uri))

          controller = klass.eager_dispatch(action, request.params.dup, env, blk)
          conditions = self.class._cache[action]
          
          Merb::Cache[controller._lookup_store(conditions)].write(controller, nil, *controller._parameters_and_conditions(conditions))
        end
      end
    end

    # After the request has finished, cache the action without holding some poor user up generating the cache (through run_later)
    # 
    # @param action<Array[Controller,Symbol], Symbol> the target option to cache (if no controller is given, the current controller is used)
    # @param options<Hash> Request options. See note for details
    # @param env<Hash>  request environment variables
    # @param blk<Block> Block run to generate the request or controller used for eager caching after trigger_action has run
    #
    # @note
    #   There are a number of options specific to eager_cache in the conditions hash
    #     - :uri the uri of the resource you want to eager cache (needed by the page store but can be provided instead by a block)
    #     - :method http method used (defaults to :get)
    #     - :params hash of params to use when sending the request to cache
    #
    # @example eager_cache  :index, :uri => '/articles' # When the update action is completed, a get request to :index with '/articles' uri will be cached (if you use the page store, this will be stored in '/articles.html')
    # @example eager_cache :index # Same after the create action but since no uri is given, the current uri is used with the default http method (:get). Useful default for resource controllers
    # @example eager_cache([Timeline, :index]) :uri => url(:timelines)}} 
    #
    # @api public
    def eager_cache(action, options = {}, env = request.env.dup, &blk)
      unless @_skip_cache
        if action.is_a?(Array)
          klass, action = *action
        else
          klass = self.class
        end

        run_later do
          env = request.env.dup
          env.merge!(options.only(:method, :uri, :params))
          controller = klass.eager_dispatch(action, {}, env, blk)
        end
      end
    end

    def skip_cache!; @_skip_cache = true; end
    def force_cache!; @_force_cache = true; end

    def _lookup_store(conditions = {})
      conditions[:store] || conditions[:stores] || default_cache_store
    end

    # Overwrite this in your controller to change the default store for a given controller
    def default_cache_store
      Merb::Cache.default_store_name
    end

    #ugly, please make me purdy'er
    def _parameters_and_conditions(conditions)
      parameters = {}

      if self.class.respond_to? :action_argument_list
        arguments, defaults = self.class.action_argument_list[action_name]
        arguments.inject(parameters) do |parameters, arg|
          if defaults.include?(arg.first)
            parameters[arg.first] = self.params[arg.first] || arg.last
          else
            parameters[arg.first] = self.params[arg.first]
          end
          parameters
        end
      end

      case conditions[:params]
      when Symbol
        parameters[conditions[:params]] = self.params[conditions[:params]]
      when Array
        conditions[:params].each do |param|
          parameters[param] = self.params[param]
        end
      end

      return parameters, conditions.except(:params, :store, :stores, :method, :uri)
    end
  end
end