require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/abstract_strategy_store_spec'

describe Merb::Cache::PageStore do
  it_should_behave_like 'all strategy stores'

  before(:each) do
    Merb::Cache.stores.clear
    Thread.current[:'merb-cache'] = nil

    @klass = Merb::Cache::PageStore[:dummy]
    Merb::Cache.register(:dummy, DummyStore)
    Merb::Cache.register(:default, @klass)

    @store = Merb::Cache[:default]
    @dummy = @store.stores.first
  end

  def dispatch(url, attrs = {})
    Merb::Dispatcher.handle(request_for(url, attrs))
  end

  def request_for(url, attrs = {})
    Merb::Request.new(Rack::MockRequest.env_for(url, attrs))
  end

  describe "examples" do

    class NhlScores < Merb::Controller
      provides :xml, :json, :yaml

      cache :index, :show
      cache :overview

      eager_cache :index, :overview, :uri => '/overview'
      eager_cache :overview, :index
      eager_cache(:overview, :show) {|params, env| build_request(build_url(:show, :team => 1), :team => 1) }

      def index
        "NHLScores index"
      end

      def show(team)
        "NHLScores show(#{team})"
      end

      def overview
        "NHLScores overview"
      end
    end

    before(:each) do
      Merb::Router.prepare do |r|
        r.match("/").to(:controller => "nhl_scores", :action => "index").name(:index)
        r.match("/show/:team").to(:controller => "nhl_scores", :action => "show").name(:show)
        r.match("/overview").to(:controller => "nhl_scores", :action => "overview").name(:overview)
      end
    end


    # NOTE: the "REQUEST_URI" => ... stuff will be removed after has_query_params? is in core.
    it "should cache the index action on the first request" do
      dispatch(url(:index), "REQUEST_URI" => url(:index))

      @dummy.data("/index.html").should == "NHLScores index"
    end

    it "should cache the yaml version of the index action request" do
      dispatch(url(:index), "HTTP_ACCEPT" => "application/x-yaml", "REQUEST_URI" => url(:index))

      @dummy.data("/index.yaml").should == "NHLScores index"
    end

    it "should cache the show action when the team parameter is a route parameter" do
      dispatch(url(:show, :team => 'redwings'), "REQUEST_URI" => url(:show, :team => 'redwings'))

      @dummy.data("/show/redwings.html").should == "NHLScores show(redwings)"
    end

    it "should cache the xml version of a request" do
      dispatch(url(:show, :team => 'redwings'), "HTTP_ACCEPT" => "application/xml", "REQUEST_URI" => url(:show, :team => 'redwings'))

      @dummy.data("/show/redwings.xml").should == "NHLScores show(redwings)"
    end


    it "should not cache the show action when the team parameter is not a route parameter" do
      pending "the has_query_params? is implemented in merb-core"
      dispatch_to(NhlScores, :show, :team => 'readwings', "REQUEST_URI" => url(:show, :team => 'redwings'))

      @dummy.vault.should be_empty
    end

    it "should not cache the action when a there is a query string parameter" do
      dispatch(url(:index, :page => 2))

      @dummy.data(url(:index)).should be_nil
    end

    it "should not cache a POST request" do
      dispatch(url(:index), "REQUEST_METHOD" => "POST")

      @dummy.data('/index.html').should be_nil
    end
    
    it "should eager cache overview after a POST request to index" do
      dispatch(url(:index), "REQUEST_METHOD" => "POST")
      
      @dummy.data('/overview.html').should == "NHLScores overview"
    end

    it "should eager cache show after a request to overview" do
      dispatch(url(:overview))
      
      @dummy.data('/show/1.html').should == "NHLScores show(1)"
    end

    it "should not eager cache during an eager cache, causing an infinit loop of eagerness" do
      dispatch(url(:overview), "REQUEST_URI" => url(:overview))

      @dummy.data("/overview.html").should == "NHLScores overview"
    end
    
    describe "controller.caches?" do      
      it "should return true for a request to overview with the :get method" do
        NhlScores.caches?(:overview, :uri => url(:overview)).should be_true
      end
      
      it "should return true for a request to overview with the :post method" do
        NhlScores.caches?(:overview, :uri => url(:overview), :method => :post).should be_false
      end
      
      it "should return false for a request to overview with query string parameters" do
        NhlScores.caches?(:overview, :uri => url(:overview, :foo => 'baz')).should be_false
      end  
    end
  end
end