# encoding: utf-8

require_relative '../lib/yaml-validator'

describe YamlValidator do
  
  describe "#validate" do
    
    describe "no en.yml file" do
      it "returns 'no en.yml' error" do
        validator = YamlValidator.new('spec/fixtures')
        errors = validator.validate()
        errors.should == 
          ['no en.yml file in the directory (an en.yml file is required as reference)']
      end
    end
    
    describe "wrong_variables scenario" do
      it "returns two errors" do
        validator = YamlValidator.new('spec/fixtures/wrong_variables')
        errors = validator.validate()
        errors.should == [
          "he.yml: parent1.key1: missing variable 'name1' (available options: name, day_of_week)",
          "he.yml: parent1.key1: missing variable 'day_of_week1' (available options: name, day_of_week)"
        ]
      end
    end
    
    describe "inconsistent_types scenario" do
      it "returns inconsistent type error" do
        validator = YamlValidator.new('spec/fixtures/inconsistent_types')
        errors = validator.validate()
        errors.should == [
          "he.yml: parent1.key1.subkey1 doesn't exist in en.yml",
          "he.yml: parent2.key2 doesn't exist in en.yml",
          "he.yml: key3 doesn't exist in en.yml",
          "he.yml: parent3.key4 doesn't exist in en.yml"
        ]
      end
    end
    
    describe "invalid yaml files" do
      it "returns invalid yaml error" do
        validator = YamlValidator.new('spec/fixtures/invalid_yml')
        errors = validator.validate()
        errors.should == [
          "invalid.yml: found character that cannot start any token " + 
            "while scanning for the next token at line 1 column 6"
        ]
      end
    end

  end
  
  describe "#validate_yaml" do
    it "returns two errors" do
      validator = YamlValidator.new('spec/fixtures/wrong_variables')
      errors = validator.validate_yaml('spec/fixtures/wrong_variables/he.yml')
      errors == [
        "he.yml: parent1.key1: missing variable 'name1' (available options: name, day_of_week)",
        "he.yml: parent1.key1: missing variable 'day_of_week1' (available options: name, day_of_week)"
      ]
    end
  end
  
  
  describe "#validate_item" do
    describe "for 'parent1.key1' = 'hello %{name1}, %{day_of_week1}'" do
      it "returns two errors" do
        validator = YamlValidator.new('spec/fixtures/wrong_variables')
        errors = validator.validate_item('parent1.key1', 'hello %{name1}, %{day_of_week1}')
        errors.should == [
          "parent1.key1: missing variable 'name1' (available options: name, day_of_week)",
          "parent1.key1: missing variable 'day_of_week1' (available options: name, day_of_week)"
        ]
      end
    end
  end
  
  describe "#get_key_en_vars" do
    describe "for 'parent1'" do
      it "returns nil" do
        validator = YamlValidator.new('spec/fixtures/wrong_variables')
        validator.get_key_en_vars('parent1').should be_nil
      end
    end
    
    describe "for 'parent1.key1'" do
      it "returns ['name', 'day_of_week']" do
        validator = YamlValidator.new('spec/fixtures/wrong_variables')
        validator.get_key_en_vars('parent1.key1').should == ['name', 'day_of_week']
      end
    end
    
    describe "for 'parent1.nonexisting_key'" do
      it "returns nil" do
        validator = YamlValidator.new('spec/fixtures/wrong_variables')
        validator.get_key_en_vars('parent1.nonexisting_key').should == nil
      end
    end
    describe "for 'parent1.nonexisting_parent.key1'" do
      it "returns nil" do
        validator = YamlValidator.new('spec/fixtures/wrong_variables')
        validator.get_key_en_vars('parent1.nonexisting_parent.key1').should == nil
      end
    end
    describe "for 'parent1.key1.nonexisting_subkey'" do
      it "returns nil" do
        validator = YamlValidator.new('spec/fixtures/wrong_variables')
        validator.get_key_en_vars('parent1.key1.nonexisting_subkey').should == nil
      end
    end
  end
  
  describe "#get_all_variables" do
    subject { YamlValidator.new(nil) }
    describe "for { parent1: { key1: 'hello %{name}' } }" do
      it "returns { parent1: { key1: ['name'] } }" do
        input = { :parent1 => { :key1 => "hello %{name}" } }
        subject.get_all_variables(input).should == { :parent1 => { :key1 => ['name'] } }
      end
    end
    describe "for { parent1: { parent2: { key1: 'hello %{name}' } } }" do
      it "returns { parent1: { parent2: { key1: ['name'] } } }" do
        input = { :parent1 => { :parent2 => { :key1 => "hello %{name}" } } }
        subject.get_all_variables(input).should ==
          { :parent1 => { :parent2 => { :key1 => ['name'] } } }
      end
    end
  end
  
  describe "#identify_variables" do
    subject { YamlValidator.new(nil) }
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
