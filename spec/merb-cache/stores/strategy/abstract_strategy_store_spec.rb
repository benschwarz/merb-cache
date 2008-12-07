require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fundamental/abstract_store_spec'


describe Merb::Cache::AbstractStrategyStore do
  describe 'all strategy stores', :shared => true do
    it_should_behave_like 'all stores'

    before(:each) do
      Merb::Cache.stores.clear
      Thread.current[:'merb-cache'] = nil
    end

    describe "contextualizing method", :shared => true do
      it "should return a subclass of itself" do
        subclass = @klass.[](Class.new(Merb::Cache::AbstractStore))
        subclass.superclass.should  == @klass
      end

      it "should set the contextualized_stores attributes" do
        subclass = @klass.[](context_class = Class.new(Merb::Cache::AbstractStore))
        subclass.contextualized_stores.first.should == context_class
      end
    end
    
    describe ".contextualize" do
      it_should_behave_like "contextualizing method"
    end

    describe ".[]" do
      it_should_behave_like "contextualizing method"
    end

    describe "#initialize" do
      it "should create an instance of the any context classes" do
        subclass = @klass.[](context_class = Class.new(Merb::Cache::AbstractStore))
        instance = subclass.new({})
        instance.stores.first.class.superclass.should == Merb::Cache::AbstractStore
      end

      it "should lookup the instance of any context names" do
        Merb::Cache.register(:foo, Class.new(Merb::Cache::AbstractStore))
        subclass = @klass.[](:foo)
        Merb::Cache.should_receive(:[]).with(:foo)
        subclass.new({})
      end
    end

    describe "#clone" do
      it "should clone each context instance" do
        subclass = @klass.[](context_class = Class.new(Merb::Cache::AbstractStore))
        instance = mock(:instance)
        context_class.should_receive(:new).and_return(instance)
        instance.should_receive(:clone)

        subclass.new.clone
      end
    end
    
    describe "#write" do
      it "should write" do
        pending
        @store.write('foo', 'bar', {:params => :hash}, :conditions => :hash).should be_true
      end
    end

    describe "#write_all" do
      it "should not raise a NotImplementedError error" do
        lambda { @store.write_all('foo', 'bar') }.should_not raise_error(NotImplementedError)
      end

      it "should accept a string key" do
        @store.write_all('foo', 'bar')
      end

      it "should accept a symbol as a key" do
        @store.write_all(:foo, :bar)
      end

      it "should accept parameters and conditions" do
        @store.write_all('foo', 'bar', {:params => :hash}, :conditions => :hash)
      end
    end
  end
end
