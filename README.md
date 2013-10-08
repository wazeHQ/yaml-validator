YAML Validator
==============


[![Build Status](https://travis-ci.org/wazeHQ/yaml-validator.png?branch=master)](https://travis-ci.org/wazeHQ/yaml-validator)

Validates .yml locale files for Ruby on Rails projects.

What does it validate?
----------------------

* Rails I18n variables:

  * Make sure users didn't translate the variables (e.g. `Hi %{user}` was translated to `Hola %{usuario}`).
  * Make sure users didn't write invalid variable syntax (e.g. `{name}` or `{name}%` instead of `%{name}`)
 
* Make sure users didn't change locked keys (searches for a file named `locked_keys` in the same folder, where each line is a regular expression).
* Check for bad characters in values (transifex sometimes adds the "⏎ " character)
* Keys that don't appear in the source language
* Checks that Ruby's YAML parser can parse the file
* Checks for missing pluralization (in languages like russian there are 4 types of pluralization: one, other, few, many)


How to run it?
----------------------

Given the following file tree:

```
config/
  locales/
    en.yml
    he.yml
    nl.yml
    fr.yml
    ...
```

Run the following command:

```bash
yaml-validator validate config/locales

or 

cd config/locales
yaml-validator
```

it will validate the files (in reference to en.yml) and show the following types of errors:

```
he.yml: parent_key.key1 doesn't exist in en.yml
fr.yml: found character that cannot start any token while scanning for the next token at line 19 column 14
nl.yml: parent_key.key1: missing variable 'var_with_typo' (available options var_without_type)

```

Changelog
=========

0.1.0
-----

* Added missing translations validation (strings that appear in en.yml but not in the other strings)

