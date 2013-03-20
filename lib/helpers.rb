module Helpers
  
  def self.normalize_yaml(yaml)
    return '' if yaml.nil?
    return yaml if yaml.is_a? String
    return yaml.to_s if yaml.is_a? Numeric
    return yaml.to_s if !!yaml == yaml # if boolean
    return ":#{yaml.to_s}" if yaml.is_a? Symbol
    yaml = array_to_hash(yaml) if yaml.is_a? Array
    
    normalized = {}
    yaml.each do |key, value|
      normalized[key] = normalize_yaml(value)
    end
    normalized
  end
  
  def self.array_to_hash(array)
    hash = {}
    array.each_with_index { |val, i| hash[i.to_s] = val }
    hash
  end

  def self.pluralization?(object)
    return false if object.nil?

    keys = object.keys.map { |k| k.to_sym }

    (keys.include? :one) and (keys.include? :other)
  end
  
end
