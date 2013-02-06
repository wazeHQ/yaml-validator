# encoding: utf-8

require_relative '../lib/verifier'

describe Verifier do
  
  describe "#verify" do
    
    it "returns two errors" do
      verifier = Verifier.new('spec/fixtures/wrong_variables')
      errors = verifier.verify()
      errors.should == [
        "he.yml: parent1.key1: missing variable 'name1' (available options: name, day_of_week)",
        "he.yml: parent1.key1: missing variable 'day_of_week1' (available options: name, day_of_week)"
      ]
    end

  end
  
  describe "#verify_yaml" do
    it "returns two errors" do
      verifier = Verifier.new('spec/fixtures/wrong_variables')
      errors = verifier.verify_yaml('spec/fixtures/wrong_variables/he.yml')
      errors == [
        "he.yml: parent1.key1: missing variable 'name1' (available options: name, day_of_week)",
        "he.yml: parent1.key1: missing variable 'day_of_week1' (available options: name, day_of_week)"
      ]
    end
  end
  
  
  describe "#validate_item" do
    describe "for 'parent1.key1' = 'hello %{name1}, %{day_of_week1}'" do
      it "returns two errors" do
        verifier = Verifier.new('spec/fixtures/wrong_variables')
        errors = verifier.validate_item('parent1.key1', 'hello %{name1}, %{day_of_week1}')
        errors.should == [
          "parent1.key1: missing variable 'name1' (available options: name, day_of_week)",
          "parent1.key1: missing variable 'day_of_week1' (available options: name, day_of_week)"
        ]
      end
    end
  end
  
  describe "#get_key_en_vars" do
    describe "for 'parent1.key1'" do
      it "returns ['name', 'day_of_week']" do
        verifier = Verifier.new('spec/fixtures/wrong_variables')
        verifier.get_key_en_vars('parent1.key1').should == ['name', 'day_of_week']
      end
    end
  end
  
  describe "#get_all_variables" do
    subject { Verifier.new(nil) }
    describe "for { parent1: { key1: 'hello %{name}' } }" do
      it "returns { parent1: { key1: ['name'] } }" do
        input = { :parent1 => { :key1 => "hello %{name}" } }
        subject.get_all_variables(input).should == { :parent1 => { :key1 => ['name'] } }
      end
    end
  end
  
  describe "#identify_variables" do
    subject { Verifier.new(nil) }
    describe "for 'Hello, hi'" do
      it "returns []" do
        subject.identify_variables('Hello, hi').should == []
      end
    end
    describe "for 'Hello, %{name}, this is %{day_of_week}" do
      it "returns ['name', 'day_of_week']" do
        string = 'Hello, %{name}, this is %{day_of_week}'
        subject.identify_variables(string).should == %w{name day_of_week}
      end
    end
  end

end
