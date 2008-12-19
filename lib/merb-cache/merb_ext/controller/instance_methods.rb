module Merb::Cache::Controller
  module InstanceMethods
    # Partial / fragment caches are written / retrieved using fetch_partial
    # Valid options are:
    # :collection => @object
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

    def _eager_cache_after(klass, action, conditions = {}, blk = nil)
      unless @skip_cache
        run_later do
          controller = klass.eager_dispatch(action, request.params.dup, request.env.dup, blk)

          Merb::Cache[controller._lookup_store(conditions)].write(controller, nil, *controller._parameters_and_conditions(conditions))
        end
      end
    end

    def eager_cache(action, conditions = {}, params = request.params.dup, env = request.env.dup, &blk)
      unless @_skip_cache
        if action.is_a?(Array)
          klass, action = *action
        else
          klass = self.class
        end

        run_later do
          controller = klass.eager_dispatch(action, params.dup, env.dup, blk)
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

      return parameters, conditions.except(:params, :store, :stores)
    end
  end
end