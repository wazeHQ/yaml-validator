
KEYS_BY_LANGUAGE = {
  :be=>[:one, :few, :many, :other],
  :bs=>[:one, :few, :many, :other],
  :by=>[:one, :few, :many, :other],
  :cs=>[:one, :few, :other],
  :de=>[:one, :few, :other],
  :es=>[:one, :few, :other],
  :hr=>[:one, :few, :many, :other],
  :iu=>[:one, :two, :other],
  :id=>[:one, :two, :other],
  :kw=>[:one, :two, :other],
  :mo=>[:one, :few, :other],
  :naq=>[:one, :two, :other],
  :ro=>[:one, :few, :other],
  :ru=>[:one, :few, :many, :other],
  :se=>[:one, :two, :other],
  :sh=>[:one, :few, :many, :other],
  :sk=>[:one, :few, :other],
  :sma=>[:one, :two, :other],
  :smi=>[:one, :two, :other],
  :smj=>[:one, :two, :other],
  :smn=>[:one, :two, :other],
  :sms=>[:one, :two, :other],
  :sr=>[:one, :few, :many, :other],
  :uk=>[:one, :few, :many, :other]
}

class PluralizationValidator
  def self.validate(language, yaml_object)
    validate_object(language, '', yaml_object)
  end

  def self.validate_object(language, full_key, yaml_object)
    return [] if yaml_object.nil?

    if Helpers.pluralization? yaml_object
      self.validate_pluralization(language, full_key, yaml_object)
    else
      errors = []
      yaml_object.each do |key, value|
        if value.is_a? Hash
          full_subkey = (full_key.empty?) ? key : "#{full_key}.#{key}"
          errors.concat validate_object(language, full_subkey, value)
        end
      end
      errors
    end
  end

  def self.validate_pluralization(language, full_key, yaml_object)
    language = language.to_sym
    if KEYS_BY_LANGUAGE.has_key? language
      errors = []
      KEYS_BY_LANGUAGE[language].each do |key|
        unless (yaml_object.has_key? key) or
          (yaml_object.has_key? key.to_s)

          errors << "missing '#{key.to_s}' pluralization for '#{full_key}'"
        end
      end
      errors
    else
      []
    end

  end
end
