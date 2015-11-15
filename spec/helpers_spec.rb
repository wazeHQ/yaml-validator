require_relative '../lib/helpers'

describe Helpers do
  describe "#normalize_yaml" do
    it "converts symbols to strings (with ':' prefix)" do
      yaml = { 'key3' => :bob }

      Helpers.normalize_yaml(yaml).should == {
        'key3' => ':bob'
      }
    end

    it "converts nil to ''" do
      yaml = { 'key3' => nil }
      Helpers.normalize_yaml(yaml).should == {
        'key3' => ''
      }
    end
    
    it "converts numbers to string" do
      yaml = { 'key3' => 123 }
      Helpers.normalize_yaml(yaml).should == {
        'key3' => '123'
      }
    end
    
    it "converts booleans to string" do
      yaml = { 'key3' => true }
      Helpers.normalize_yaml(yaml).should == {
        'key3' => 'true'
      }
    end
    
    it "converts arrays to hashes" do
      yaml = { 'key1' => 'value1',
        'key2' => [ 'value2', nil, :bla ],
        'parent1' => { 'key3' => [ :bob ] } }

      Helpers.normalize_yaml(yaml).should == {
        'key1' => 'value1',
        'key2' => { '0' => 'value2', '1' => '', '2' => ':bla' },
        'parent1' => { 'key3' => { '0' => ':bob' } }
      }
    end
  end
  
  describe "#array_to_hash" do
    it "returns hash with numeric indexes" do
      Helpers.array_to_hash(['a','b']).should == { '0' => 'a', '1' => 'b' }
    end
  end

  describe "#pluralization?" do
    it "returns true when object has :one and :other" do
      Helpers.pluralization?(:one => 'one', :other => 'other').should be true
    end
    it "returns true when object has 'one' and 'other'" do
      Helpers.pluralization?('one' => 'one', 'other' => 'other').should be true
    end
    it "returns false for {}" do
      Helpers.pluralization?({}).should be false
    end
  end

end
