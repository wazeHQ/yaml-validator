# encoding: utf-8
require 'yaml'
require 'yaml-validator/version'
require_relative './helpers'
require_relative './pluralization-validator'
require_relative './sanitized-html-validator'
require_relative './locked_keys'

class YamlValidator
  
  def initialize(path, options = {})
    @options = options
    @root_path = path
    @locked_keys = LockedKeys.new(@root_path) unless @root_path.nil?
  end
  
  def en
    return @en unless @en.nil?
    fullpath = File.join(@root_path, 'en.yml')
    return nil unless File.readable?(fullpath)

    @en = YAML.load_file(fullpath)['en']
    @en = Helpers.normalize_yaml(@en)
  end
  
  def en_with_vars
    return nil if en.nil?
    @en_with_vars ||= get_all_variables(en)
  end
  
  def validate()
    if en_with_vars.nil?
      return ["#{@root_path} : no en.yml file in the directory (an en.yml file is required as reference)"]
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
    
    errors = validate_root_language(yaml_object, File.basename(filename))

    yaml_object = yaml_object[yaml_object.keys[0]]
    yaml_object = Helpers.normalize_yaml(yaml_object)
    errors += validate_yaml_object('', yaml_object)
    if @options[:missing]
      errors.concat find_missing_translations(yaml_object)
      errors.concat find_missing_pluralizations(filename, yaml_object)
    end

    if @options[:sanitize]
      errors.concat find_unsanitized_html(filename, yaml_object)
    end
    
    errors.map { |err| "#{@root_path}#{filename}: #{err}" }
  end
  
  def validate_root_language(yaml_object, file_name)
    errors = []

    lang = yaml_object.keys.first
    if lang != file_name.split(".").first
      errors << "invalid root language (#{lang})"
    end

    errors
  end

  def validate_yaml_object(full_key, yaml_object)
    return [] if yaml_object.nil?
    errors = []
    is_pluralization = Helpers.pluralization? yaml_object
    
    yaml_object.each do |key, value|
      full_subkey = (full_key.empty?) ? key : "#{full_key}.#{key}"
      if value.is_a? String
        errors.concat validate_item(full_subkey, value, is_pluralization)
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

  def find_missing_pluralizations(filename, yaml_object)
    language = File.basename(filename, '.*')
    PluralizationValidator.validate(language, yaml_object)
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
  
  def validate_item(full_key, value, is_pluralization = false)
    errors = validate_item_vars(full_key, value, is_pluralization)
    errors.concat validate_item_characters(full_key, value)
    errors.concat validate_locked_key(full_key, value)
    errors
  end

  def validate_locked_key(full_key, value)
    errors = []
    if @locked_keys.locked? full_key
      locked_value = find_english_value(full_key)
      if locked_value != value
        errors << "#{full_key}: locked key value changed from '#{locked_value}' to '#{value}'"
      end
    end
    errors
  end

  def find_english_value(full_key)
    self.class.find_key_in_yaml_object(full_key, en)
  end

  def validate_item_characters(full_key, value)
    bad_chars = '⏎'
    bad_chars_found = []
    bad_chars.each_char do |ch|
      if value.include? ch
        bad_chars_found << ch
      end
    end

    if bad_chars_found.any?
      return ["#{full_key}: bad characters (#{bad_chars_found.join(', ')} ) in '#{value}'"]
    else
      return []
    end
  end

  def validate_item_vars(full_key, value, is_pluralization = false)
    real_vars = get_key_en_vars(full_key)
    if real_vars.nil?
      if is_pluralization
        return []
      else
        return ["#{full_key} doesn't exist in en.yml"]
      end
    end

    syntax_error = /(^|[^%]){[^}]+}%?/.match(value)
    unless syntax_error.nil?
      return [
        "#{full_key}: invalid syntax '#{syntax_error}'"
      ]
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
    string.scan(/%\{([^}]+)\}/).map(&:first)
  end

  def find_unsanitized_html(filename, yaml_object)
    language = File.basename(filename, '.*')
    SanitizedHtmlValidator.validate(language, yaml_object)
  end
end

