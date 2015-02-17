# encoding: utf-8

require_relative '../lib/yaml-validator'

describe YamlValidator do
  
  describe "#validate" do
    
    describe "no en.yml file" do
      it "returns 'no en.yml' error" do
        validator = YamlValidator.new('spec/fixtures/no_en')
        errors = validator.validate()
        errors.should == 
          ['spec/fixtures/no_en : no en.yml file in the directory (an en.yml file is required as reference)']
      end
    end
    
    describe "numbered keys scenario" do
      it "returns no errors" do
        validator = YamlValidator.new('spec/fixtures/numbered_keys')
        errors = validator.validate()
        errors.should be_empty
      end
    end
    
    
    describe "wrong_variables scenario" do
      it "returns errors" do
        validator = YamlValidator.new('spec/fixtures/wrong_variables')
        errors = validator.validate()
        errors.should == [
          "spec/fixtures/wrong_variables/he.yml: parent1.key1: missing variable 'name1' (available options: name, day_of_week)",
          "spec/fixtures/wrong_variables/he.yml: parent1.key1: missing variable 'day_of_week1' (available options: name, day_of_week)",
          "spec/fixtures/wrong_variables/he.yml: parent1.key2: invalid syntax ' {name1}%'",
          "spec/fixtures/wrong_variables/he.yml: parent1.key3: invalid syntax ' {name1}'"
        ]
      end
    end

    describe "locked_keys scenario" do
      it "returns errors" do
        validator = YamlValidator.new('spec/fixtures/locked_keys', missing: false)
        errors = validator.validate()
        errors.should == [
          "spec/fixtures/locked_keys/es.yml: locked_key2: locked key value changed from 'locked value' to 'changed value'",
          "spec/fixtures/locked_keys/es.yml: locked_key3: locked key value changed from 'locked value' to 'changed value'",
          "spec/fixtures/locked_keys/es.yml: key3.locked_subkey1: locked key value changed from 'locked value' to 'changed value'",
          "spec/fixtures/locked_keys/es.yml: key3.locked_subkey2: locked key value changed from 'locked value' to 'changed value'",
          "spec/fixtures/locked_keys/es.yml: items.0.locked_key1: locked key value changed from 'locked value' to 'changed value'",
          "spec/fixtures/locked_keys/es.yml: items.1.locked_key1: locked key value changed from 'locked value' to 'changed value'"
        ]
      end
    end

    describe "bad_chars scenario" do
      it "returns two errors" do
        validator = YamlValidator.new('spec/fixtures/bad_chars')
        errors = validator.validate()
        errors.should == [
          "spec/fixtures/bad_chars/he.yml: key1: bad characters (⏎ ) in 'line1 ⏎ line2'",
        ]
      end
    end
    
    describe "inconsistent_types scenario" do
      it "returns inconsistent type error" do
        validator = YamlValidator.new('spec/fixtures/inconsistent_types', missing: true)
        errors = validator.validate()
        errors.should == [
          "spec/fixtures/inconsistent_types/he.yml: parent1.key1.subkey1 doesn't exist in en.yml",
          "spec/fixtures/inconsistent_types/he.yml: parent2.key2 doesn't exist in en.yml",
          "spec/fixtures/inconsistent_types/he.yml: key3 doesn't exist in en.yml",
          "spec/fixtures/inconsistent_types/he.yml: parent3.key4 doesn't exist in en.yml",
          "spec/fixtures/inconsistent_types/he.yml: missing translation for parent1.key1 ('Hello, %{name}, this is %{day_of_week}')",
          "spec/fixtures/inconsistent_types/he.yml: missing translation for parent2.key2.subkey ('bla bla')"
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
    
    describe "missing translations" do
      it "returns invalid yaml error" do
        validator = YamlValidator.new('spec/fixtures/missing_translations', missing: true)
        errors = validator.validate()
        errors.should == [
          "spec/fixtures/missing_translations/he.yml: missing translation for key2 ('value2')",
          "spec/fixtures/missing_translations/he.yml: missing translation for parent2.key3 ('value3')",
          "spec/fixtures/missing_translations/he.yml: missing translation for parent3.2 ('three')",
          "spec/fixtures/missing_translations/he.yml: missing translation for parent3.3 ('')",
        ]
      end
    end

    describe "weird pluralizations" do
      it "returns missing pluralizations error" do
        validator = YamlValidator.new('spec/fixtures/weird_pluralizations', missing: true)
        errors = validator.validate()
        errors.should == [
          "spec/fixtures/weird_pluralizations/ru.yml: missing 'few' pluralization for 'dogs'",
          "spec/fixtures/weird_pluralizations/ru.yml: missing 'many' pluralization for 'dogs'",
        ]
      end
    end

  end
  
  describe "#validate_yaml" do
    it "returns two errors" do
      validator = YamlValidator.new('spec/fixtures/wrong_variables')
      errors = validator.validate_yaml('spec/fixtures/wrong_variables/he.yml')
      errors == [
        "spec/fixtures/wrong_variables/he.yml: parent1.key1: missing variable 'name1' (available options: name, day_of_week)",
        "spec/fixtures/wrong_variables/he.yml: parent1.key1: missing variable 'day_of_week1' (available options: name, day_of_week)"
      ]
    end
  end
  
  describe "#validate_root_language" do
    describe "file_name = he.yml, yaml_object = {es: parent1: 'foo'}" do
      it "returns one error" do
        validator = YamlValidator.new('spec/fixtures/wrong_root')
        errors = validator.validate()
        errors.should == [
          "spec/fixtures/wrong_root/he.yml: invalid root language (es)",
        ]

      end
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
  
  describe "#find_missing_translations" do
    it "returns the missing translation keys" do
      validator = YamlValidator.new('spec/fixtures/missing_translations')
      
      yaml_object = YAML.load_file('spec/fixtures/missing_translations/he.yml')['he']
      yaml_object = Helpers.normalize_yaml(yaml_object)
      
      errors = validator.find_missing_translations(yaml_object)
      errors.should == [
        "missing translation for key2 ('value2')",
        "missing translation for parent2.key3 ('value3')",
        "missing translation for parent3.2 ('three')",
        "missing translation for parent3.3 ('')"
      ]
    end
  end
  
  describe "#find_key_in_yaml_object" do
    it "handles subkeys" do
      yaml_object = { 'parent1' => { 'key1' => 'value1' } }
      YamlValidator.find_key_in_yaml_object('parent1.key1', yaml_object).should == 'value1'
    end
    
    it "handles root keys" do
      yaml_object = { "key2" => 'value2' }
      YamlValidator.find_key_in_yaml_object('key2', yaml_object).should == 'value2'
    end
    
    it "returns nil when a root key doesn't exist" do
      yaml_object = { "key2" => 'value2' }
      YamlValidator.find_key_in_yaml_object('key1', yaml_object).should be_nil
    end
    
    it "returns nil when a subkey doesn't exist" do
      yaml_object = { "parent1" => { "key2" => 'value2' } }
      YamlValidator.find_key_in_yaml_object('parent1.key1', yaml_object).should be_nil
    end
    
    it "returns nil when a subkey is an object" do
      yaml_object = { "parent1" => { "parent2" => { "key1" => 'value1' } } }
      YamlValidator.find_key_in_yaml_object('parent1.key2', yaml_object).should be_nil
    end

  end

  describe "#sanitized_html" do
    it "returns the non-sanitized values" do
      validator = YamlValidator.new('spec/fixtures/sanitized_html')
      
      filename = 'spec/fixtures/sanitized_html/en.yml'
      yaml_object = YAML.load_file(filename)['en']
      yaml_object = Helpers.normalize_yaml(yaml_object)
      
      errors = validator.find_unsanitized_html(filename, yaml_object)
      errors.should == [
        "unsanitized html in 'en.invalid1' (this is an <a href=\"spam.com\">invalid</a> value)",
        "unsanitized html in 'en.invalid2' (this is an <strong onclick=\"spam.com\">invalid</strong> value)"
      ]
    end
  end
  
end
