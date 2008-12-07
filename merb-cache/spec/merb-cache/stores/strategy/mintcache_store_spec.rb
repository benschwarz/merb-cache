require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/abstract_strategy_store_spec'

describe Merb::Cache::MintCacheStore do
  it_should_behave_like 'all strategy stores'

  before(:each) do
    @klass = Merb::Cache::MintCacheStore
    @store = Merb::Cache::MintCacheStore[DummyStore].new
  end
  
  describe "when writing a cache" do
    it "should write three keys" do
      @store.write('foo', 'body')
      %w(foo foo_validity foo_data).each do |key|
        @store.read(key).should_not be_nil
      end
    end
    
    it "should write a validity key that is a time object" do
      @store.write('foo', 'body')
      @store.read('foo_validity').first.should be_a_kind_of Time
    end
    
    it "should write a data key that is the same as a regular key" do
      @store.write('foo', 'body')
      @store.read('foo_data').first.should == @store.read('foo').first
    end
    
    it "should write the additional keys with double expiry time" do
      @store.write('foo', 'body', {}, :expire_in => 10)
      @store.read('foo_data')[2][:expire_in].should eql 20
    end
    
    it "should receive write_all three times (key, key_validity and key_data for write_all" do
      @store.write_all('foo', 'body')
      %w(foo foo_validity foo_data).each do |key|
        @store.read(key).should_not be_nil
      end
    end
  end
end