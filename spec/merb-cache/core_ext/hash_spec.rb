require File.dirname(__FILE__) + '/../../spec_helper'

describe Hash do
  
  describe "to_sha1" do
    before(:each) do
      @params = {:id => 1, :string => "string", :symbol => :symbol}
    end
    
    it{@params.should respond_to(:to_sha2)}
    
    # This sec only has meaning in ruby 1.9 that uses an ordered hash
    it "should encode the hash by alphabetic key" do
      x = @params.to_sha2
      y = {:id => 1, :symbol => :symbol, :string => "string"}.to_sha2
      x.should == y
    end
    
    it "should not have any collisions between different values (using arrays)" do
      x = {'test' => ['at','vc'], 'test2' => 'b'}.to_sha2
      y = {'test' => ['atv', 'c'], 'test2' => 'b'}.to_sha2
      puts x != y
      x.should_not == y
    end
    
    it "should encode the keys" do
      x = {'key' => [1,2,3]}.to_sha2
      y = {'test' => [1,2,3]}.to_sha2
      x.should_not == y
    end
    
    it "should not make a distinction between symbol and strings for keys" do
      x = {:key => 1}.to_sha2
      y = {'key' => 1}.to_sha2
      x.should == y
    end
    
    it "should not have any collisions between keys and values" do
      x = {'key' => 'ab'}.to_sha2
      y = {'keya' => 'b'}.to_sha2
      x.should_not == y
    end
    
    it "should not have any collisions between the values of two different keys" do
      x = {'a' => 'abc', 'b' => 'def'}.to_sha2
      y = {'a' => 'abcd', 'b' => 'ef'}.to_sha2
      x.should_not == y
    end
  end
  
end