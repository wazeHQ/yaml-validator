class Validator
  
  def initialize(root_path)
    @root_path = root_path
  end
  
  def en_with_vars
    @en ||= YAML.load_file(File.join(@root_path, 'en.yml'))['en']
    @en_with_vars ||= get_all_variables(@en)
  end
  
  def validate()
    yml_files = File.join(@root_path, '*.yml')
    errors = []
    Dir[yml_files].each do |filename|
      errors.concat validate_yaml(filename)
    end
    errors
  end
  
  def validate_yaml(filepath)
    yaml_object = YAML.load_file(filepath)
    yaml_object = yaml_object[yaml_object.keys[0]]
    errors = validate_yaml_object('', yaml_object)
    
    filename = File.basename(filepath)
    errors.map { |err| "#{filename}: #{err}" }
  end
  
  def validate_yaml_object(full_key, yaml_object)
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
  
  def validate_item(full_key, value)
    real_vars = get_key_en_vars(full_key)
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
      position = position[key]
    end
    position
  end
  
  def get_all_variables(yaml_object)
    with_vars = {}
    yaml_object.each do |key, value|
      if value.is_a? String
        with_vars[key] = identify_variables(value)
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

