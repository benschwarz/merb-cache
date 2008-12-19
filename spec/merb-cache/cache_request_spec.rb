require File.dirname(__FILE__) + '/../spec_helper'

describe Merb::Cache::CacheRequest do
  it "should subclass Merb::Request" do
    Merb::Cache::CacheRequest.superclass.should == Merb::Request
  end

  describe "#env" do
    it "can be specified in the constructor" do
      Merb::Cache::CacheRequest.new('', {}, 'foo' => 'bar').env['foo'].should == 'bar'
    end
  end

  describe "#env[Merb::Const::REQUEST_URI]" do
    it "should give the uri with the query string" do
      Merb::Cache::CacheRequest.new('/test?q=1').env[Merb::Const::REQUEST_URI].should == '/test?q=1'
    end
  end

  describe "#host" do
    it "should return the correct host if the uri is absolute" do
      Merb::Cache::CacheRequest.new('http://example.org:453/').host.should == "example.org:453"
    end
  end

  describe "#method" do
    it "should be :get by default" do
      Merb::Cache::CacheRequest.new('/test?q=1').method.should == :get
    end
    
    it "should be set by the :method parameter" do
      Merb::Cache::CacheRequest.new('/test?q=1', :method => :put).method.should == :put
    end
  end

  describe "#path" do
    it "can be specified without manipulating the env" do
      Merb::Cache::CacheRequest.new('/path/to/foo').path.should == '/path/to/foo'
    end
    
    it "should return the path without the query string" do
      Merb::Cache::CacheRequest.new('/path/to/foo?q=1').path.should == '/path/to/foo'
    end
  end

  describe "#params" do
    it "can be specified without manipulating the env" do
      Merb::Cache::CacheRequest.new('/', 'foo' => 'bar').params.should == {'foo' => 'bar'}
    end
  end

  describe "#subdomains" do 
    it "should return the correct subdomains if the uri is absolute" do
      Merb::Cache::CacheRequest.new('http://test.example.org:453/').subdomains.should == ['test']
    end
  end

  describe "#uri" do
    it "should give the uri without the query string" do
      Merb::Cache::CacheRequest.new('/test?q=1').uri.should == '/test'
    end
  end
  
  it "should be compatiple with page store's way of detecting the presence of a query string" do
    request = Merb::Cache::CacheRequest.new("/test?q=1")
    (request.env[Merb::Const::REQUEST_URI] == request.uri).should be_false
    request = Merb::Cache::CacheRequest.new("/test")
    (request.env[Merb::Const::REQUEST_URI] == request.uri).should be_true
  end

  it "should setup a default env" do
    Merb::Cache::CacheRequest.new('').env.should_not be_empty
  end
end