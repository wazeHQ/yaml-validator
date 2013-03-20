#!/usr/bin/env ruby

require 'pp'

RAILS_I18N_PATH = File.expand_path("~/playground/rails-i18n")


NORMAL_RULES = ['one_other', 'other', 'one_upto_two_other', 'one_with_zero_other']

KEYS_BY_RULE = {
  'west_slavic' => [:one, :few, :other],
  'east_slavic' => [:one, :few, :many, :other],
  'romanian' => [:one, :few, :other],
  'one_two_other' => [:one, :two, :other]
}

PLURALS_PATH = File.join(RAILS_I18N_PATH, "rails/pluralization")

def find_rule(pluralization_file)
  rule = `grep require #{pluralization_file}`
  if rule.length > 0
    /^.*pluralizations\/(.*)'$/.match(rule)[1]
  else
    nil
  end
end

all = {}
Dir["#{PLURALS_PATH}/*.rb"].each do |file|
  lang = File.basename(file, '.*')
  rule = find_rule(file)
  unless rule.nil? or NORMAL_RULES.include? rule
    keys = KEYS_BY_RULE[rule]
    all[lang.to_sym] = keys
  end
end

pp all
