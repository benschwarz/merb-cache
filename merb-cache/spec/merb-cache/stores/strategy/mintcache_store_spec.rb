require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/abstract_strategy_store_spec'

describe Merb::Cache::MintCacheStore do
  it_should_behave_like 'all strategy stores'

  before(:each) do
    @klass = Merb::Cache::MintCacheStore
    @store = Merb::Cache::MintCacheStore[DummyStore].new
  end
  
  describe "when writing a cache" do
    it "should receive write three times (key, key_validity and key_data) for write" do
      @store.stores.first.should_receive(:write).once.with('foo', 'body', {}, {})
      @store.stores.first.should_receive(:write).once.with('foo_validity', 'body', {}, {:expire_in => 3600})
      @store.stores.first.should_receive(:write).once.with('foo_data', 'body', {}, {:expire_in => 3600})
      
      @store.write('foo', 'body')
    end
    
    it "should receive write_all three times (key, key_validity and key_data for write_all" do
      @store.stores.first.should_receive(:write_all).once.with('foo', 'body', {}, {})
      @store.stores.first.should_receive(:write_all).once.with('foo_validity', 'body', {}, {})
      @store.stores.first.should_receive(:write_all).once.with('foo_data', 'body', {}, {})
      
      @store.write_all('foo', 'body')
    end
  end
  
  describe "when reading a cache" do
    it "should receive read three times (key, key_validity and key_data)" do
      @store.stores.first.should_receive(:read).once.with('foo', {})
      @store.stores.first.should_receive(:read).once.with('foo_validity', {})
      @store.stores.first.should_receive(:read).once.with('foo_data', {})
      
      @store.read('foo')
    end 
  end
end