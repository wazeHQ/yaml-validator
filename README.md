YAML Validator
==============

[![Build Status](https://travis-ci.org/wazeHQ/yaml-validator.png?branch=master)](https://travis-ci.org/wazeHQ/yaml-validator)

Validates .yml locale files for Ruby on Rails projects.

What does it validate?
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
yaml-validator config/locales

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

