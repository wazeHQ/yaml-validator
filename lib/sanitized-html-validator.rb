require 'sanitize'

class SanitizedHtmlValidator
  def self.validate(language, yaml_object)
    validate_object(language, '', yaml_object)
  end

  def self.validate_object(language, full_key, yaml_object)
    return [] if yaml_object.nil?

    errors = []
    yaml_object.each do |key, value|
      full_subkey = (full_key.empty?) ? key : "#{full_key}.#{key}"

      if value.is_a? String
        unless valid_html?(value)
          errors << "unsanitized html in '#{language}.#{full_subkey}' (#{value})"
        end
      elsif value.is_a? Hash
        errors.concat validate_object(language, full_subkey, value)
      end
    end
    errors
  end

  def self.valid_html?(html)
    html.gsub!(/(\s)&\s/, '&amp;')
    sanitized = Sanitize.clean(html, elements: [ 'strong', 'br', 'span', 'b', 'i' ]) 
    html == sanitized
  end
end
