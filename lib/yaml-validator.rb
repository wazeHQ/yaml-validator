require 'yaml'
require 'yaml-validator/version'
require_relative './helpers'

class YamlValidator
  
  def initialize(root_path)
    @root_path = root_path
  end
  
  def en
    return @en unless @en.nil?

    fullpath = File.join(@root_path, 'en.yml')
    return nil unless File.exists?(fullpath)

    @en = YAML.load_file(fullpath)['en']
    @en = Helpers.normalize_yaml(@en)
  end
  
  def en_with_vars
    return nil if en.nil?
    @en_with_vars ||= get_all_variables(en)
  end
  
  def validate()
    if en_with_vars.nil?
      return ["no en.yml file in the directory (an en.yml file is required as reference)"]
    end
    yml_files = File.join(@root_path, '*.yml')
    errors = []
    Dir[yml_files].each do |filename|
      next if File.basename(filename) == 'en.yml'
      errors.concat validate_yaml(filename)
    end
    errors
  end
  
  def validate_yaml(filepath)
    filename = File.basename(filepath)
    
    begin
      yaml_object = YAML.load_file(filepath)
    rescue Psych::SyntaxError => e
      return [e.message.sub(/^\([^)]+\)/, filename)]
    end
    
    yaml_object = yaml_object[yaml_object.keys[0]]
    yaml_object = Helpers.normalize_yaml(yaml_object)
    errors = validate_yaml_object('', yaml_object)
    errors.concat find_missing_translations(yaml_object)
    
    errors.map { |err| "#{filename}: #{err}" }
  end
  
  def validate_yaml_object(full_key, yaml_object)
    return [] if yaml_object.nil?
    errors = []
    
    yaml_object.each do |key, value|
      full_subkey = (full_key.empty?) ? key : "#{full_key}.#{key}"
      if value.is_a? String
        errors.concat validate_item(full_subkey, value)
      else
        errors.concat validate_yaml_object(full_subkey, value)
      end
    end
    errors
  end
  
  def find_missing_translations(yaml_object)
    find_missing_translations_in_en_object('', en, yaml_object)
  end
  
  def find_missing_translations_in_en_object(full_key, en_yaml_object, yaml_object)
    return [] if en_yaml_object.nil?
    errors = []
    
    en_yaml_object.each do |key, value|
      full_subkey = (full_key.empty?) ? key : "#{full_key}.#{key}"
      if value.is_a? String or value.is_a? Symbol
        if self.class.find_key_in_yaml_object(full_subkey, yaml_object).nil?
          errors << "missing translation for #{full_subkey} ('#{value}')"
        end
      else
        errors.concat find_missing_translations_in_en_object(full_subkey, value, yaml_object)
      end
    end
    errors
  end
  
  def self.find_key_in_yaml_object(full_key, yaml_object)
    position = yaml_object
    full_key.split('.').each do |key|
      return nil unless position.is_a? Hash
      position = position[key]
    end
    
    if position.is_a? String or position.is_a? Symbol
      position
    else
      nil
    end
  end
  
  def validate_item(full_key, value)
    real_vars = get_key_en_vars(full_key)
    if real_vars.nil?
      return ["#{full_key} doesn't exist in en.yml"]
    end

    used_vars = identify_variables(value)

    errors = []
    used_vars.each do |var|
      unless real_vars.include? var
        errors << "#{full_key}: missing variable '#{var}' (available options: #{real_vars.join(', ')})"
      end
    end
    errors
  end
  
  def get_key_en_vars(full_key)
    position = en_with_vars
    full_key.split('.').each do |key|
      return nil if position.is_a? Array
      return nil if position.nil?
      position = position[key]
    end
    if position.is_a? Array
      position
    else
      nil
    end
  end
  
  def get_all_variables(yaml_object)
    return {} if yaml_object.nil?
    with_vars = {}
    
    yaml_object.each do |key, value|
      if value.is_a? String
        with_vars[key] = identify_variables(value)
      elsif value.is_a? Symbol
        with_vars[key] = {}
      else
        with_vars[key] = get_all_variables(value)
      end
    end
    with_vars
  end
  
  def identify_variables(string)
    string.scan(/%{([^}]+)}/).map { |v| v[0] }
  end
  
end

