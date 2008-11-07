module Merb::Cache
  class MintCacheStore < AbstractStrategyStore
    
    def writable?(key, parameters = {}, conditions = {})
      @stores.capture_first {|s| s.writable?(key, parameters, conditions)}
    end
    
    def read(key, parameters = {})
      cache_read = @stores.capture_first {|c| c.read(key, parameters)}
      return cache_read || read_mint_cache(key, parameters)
    end
    
    def write(key, data = nil, parameters = {}, conditions = {})
      if writable?(key, parameters, conditions)
        write_mint_cache(key, data, parameters, conditions)
        @stores.capture_first {|c| c.write(key, data, parameters, conditions)}
      end
    end
    
    # if you're wrapping multiple stores in a strategy store, 
    # it will write to all the wrapped stores, not just the first store that is successful
    def write_all(key, data = nil, parameters = {}, conditions = {})
      if writable?(key, parameters, conditions)
        key_write = @stores.map {|c| c.write_all(key, data, parameters, conditions)}.all?
        validity_write = @stores.map {|c| c.write_all(validity_key(key), data, parameters, conditions)}.all?
        data_write = @stores.map {|c| c.write_all(data_key(key), data, parameters, conditions)}.all?

        return (key_write and validity_write and data_write) ? true : false
      end
    end
    
    def fetch(key, parameters = {}, conditions = {}, &blk)
      wrapper_blk = lambda { blk.call }
      cache_read = read(key, parameters) || @stores.capture_first {|s| s.fetch(key, parameters, conditions, &wrapper_blk)}
      return cache_read || read_mint_cache(key, parameters)
    end
    
    def exists?(key, parameters = {})
      @stores.capture_first {|c| c.exists?(key, parameters)} || @stores.capture_first {|c| c.exists?(validity_key(key), parameters)}
    end
    
    def delete(key, parameters = {})
      [key, validity_key(key), data_key(key)].map{|k| @stores.map {|c| c.delete(k, parameters)} }.flatten.any?
    end
    
    def delete_all!
      @stores.map {|c| c.delete_all! }.all?
    end
    
    private
    def validity_key(key); "#{key}_validity"; end
    def data_key(key); "#{key}_data"; end
    
    def write_mint_cache(key, data = nil, parameters = {}, conditions = {})
      expiry = (conditions[:expire_in].nil?) ? 3600 : (conditions[:expire_in] * 2)
      
      @stores.capture_first {|c| c.write(validity_key(key), (Time.now + expiry), parameters, conditions.merge({:expire_in => expiry}))}
      @stores.capture_first {|c| c.write(data_key(key), data, parameters, conditions.merge({:expire_in => expiry}))}
    end
    
    def read_mint_cache(key, parameters = {})
      validity_time = @stores.capture_first {|c| c.read(validity_key(key), parameters)}
      data = @stores.capture_first {|c| c.read(data_key(key), parameters)}
      
      unless validity_time.nil?
        if Time.now < validity_time
          write(key, data, parameters)
          return nil
        end
      end
      
      return data
    end
  end
end