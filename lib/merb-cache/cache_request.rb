module Merb
  module Cache
    class CacheRequest < Merb::Request
      
      attr_accessor :params

      def initialize(uri = "", params = {}, env = {})
        uri = URI(uri || '/')
        
        env[Merb::Const::REQUEST_URI]  = uri.respond_to?(:request_uri) ? uri.request_uri : uri.to_s
        env[Merb::Const::HTTP_HOST]    = uri.host + (uri.port != 80 ? ":#{uri.port}" : '') if uri.host
        env[Merb::Const::SERVER_PORT]  = uri.port.to_s   if uri.port
        env[Merb::Const::QUERY_STRING] = uri.query.to_s  if uri.query
        
        env[Merb::Const::REQUEST_METHOD] = env.delete(:method).to_s.upcase if env[:method]
        
        super(DEFAULT_ENV.merge(env))
        
        self.env[Merb::Const::REQUEST_PATH] = self.env[Merb::Const::PATH_INFO] = self.path
        @params = params
      end

      DEFAULT_ENV = Mash.new({
        'SERVER_NAME' => 'localhost',
        'HTTP_ACCEPT_ENCODING' => 'gzip,deflate',
        'HTTP_USER_AGENT' => 'Ruby/Merb (ver: ' + Merb::VERSION + ') merb-cache',
        'SCRIPT_NAME' => '/',
        'SERVER_PROTOCOL' => 'HTTP/1.1',
        'HTTP_CACHE_CONTROL' => 'max-age=0',
        'HTTP_ACCEPT_LANGUAGE' => 'en,ja;q=0.9,fr;q=0.9,de;q=0.8,es;q=0.7,it;q=0.7,nl;q=0.6,sv;q=0.5,nb;q=0.5,da;q=0.4,fi;q=0.3,pt;q=0.3,zh-Hans;q=0.2,zh-Hant;q=0.1,ko;q=0.1',
        'HTTP_HOST' => 'localhost',
        'REMOTE_ADDR' => '127.0.0.1',
        'SERVER_SOFTWARE' => 'Mongrel 1.1',
        'HTTP_KEEP_ALIVE' => '300',
        'HTTP_REFERER' => 'http://localhost/',
        'HTTP_ACCEPT_CHARSET' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
        'HTTP_VERSION' => 'HTTP/1.1',
        'REQUEST_METHOD' => 'GET',
        'SERVER_PORT' => '80',
        'GATEWAY_INTERFACE' => 'CGI/1.2',
        'HTTP_ACCEPT' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
        'HTTP_CONNECTION' => 'keep-alive'
      }) unless defined?(DEFAULT_ENV)
    end
  end
end