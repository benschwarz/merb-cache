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
      @store.write('foo', 'body')
      %w(foo foo_validity foo_data).each do |key|
        @store.read(key).should_not be_nil
      end
    end
    
    it "should receive write_all three times (key, key_validity and key_data for write_all" do
      @store.write_all('foo', 'body')
      %w(foo foo_validity foo_data).each do |key|
        @store.read(key).should_not be_nil
      end
    end
  end
end