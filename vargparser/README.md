# `VARGPARSER`

##### Raw script (master): https://git.io/v7gXU

## About
A script that allows for easy command line arguments pattern parsing.

## Usage
For now it is only possible to import script directly as source:
```
#!/usr/bin/env bash

#####################
# Parsing arguments
#####################

arg_pattern="#tag #flag? debug?"
source /dev/stdin "${arg_pattern}" "$@" <<< "$(curl -L -s https://git.io/v7gXU)"

# Notice the quotes around pattern and $@
# They are required in order to not break the "multi word strings"

####################
# Main script body
####################

if [[ ${_debug} == 1 ]]; then
  echo "[DEBUG] Starting main script body"
fi

echo "Specified tag is: ${_tag}"
if [[ ${_flag} == 1 ]]; then
  echo "You have selected the flag!"
fi
```

This script may then be called like this:
1. `script.sh --tag some_tag --flag --debug`
2. `script.sh -f -t some_tag --debug`
3. `script.sh -t some_tag --flag`

- The order of the arguments does not matter
- You may specify whether argument may be shortened or not
- You may specify whether argument takes a value
- Parsed arguments are automatically stored into variables

## Pattern
First argument of the `vargparser` script if the "pattern" string.
Pattern string must consist of a "arg patterns" separated by space.
Each arg pattern looks like this:
```
[#]<full_arg_name>[?]
```

### <full_arg_name>
Arg pattern must contain a full argument name that consists of
**more than one alphabet letters, digits, or minus sign**.

Valid names:
- `qwe`
- `rty22`
- `6v`
- `get-some`

Invalid names:
- `q`
- `rty22*`
- `get=some`
- `^6v`

**Multiple arguments cannot have similar full names!**
If that happens - script is interrupted with exit status 1. 

As long s arg pattern has a name - argument may be specified as:
```
--<full arg name>
```

##### Result variable name
Result variable will be generated from an argument **ONLY** if it's present.
Variable name with be the full name of the argument with `_` prefix and
minuses replaced with underscores.

Examples:
- `qwe` -> `${_qwe}`
- `6V` -> `${_6V}`
- `get-some` -> `${_get_some}` 

### \#
Optional prefix `#` signals that argument has the short version.
Short version argument is automatically generated from the first letter
of the full argument name.

So argument with a pattern `#tag` may be specified in two forms:
1. `--tag`
2. `-t`

The same variable `${_tag}` will be generated in both cases.

**Multiple short arguments cannot start with the same letter!**
If that happens - script is interrupted with exit status 1.

- Valid example: `#tag task` (may be specified as `-t --task`)
- Invalid example: `#tag #task`

### Types

#### String (default)
By default all arguments treated as requiring a non-empty string value.
So if you set the pattern as `#tag task`, both arguments will
require a value, that may be specified like this:
```
-t some-tag --task 'do some'
```

The specified string will be the value of the generated variable:
```
echo ${_tag} # some-tag
echo ${_task} # do some
```

#### Boolean?
Boolean flag may have no additional value. The only information is
whether the flag itself present or not. If your arg pattern ends
with `?` - then it will create a boolean argument.

So argument `flag?` may be specified like this:
```
--flag
```

And argument `#flag?` may be specified both ways:
1. `--flag`
2. `-f`

The generated variable will have value `1` **IF** the flag is present,
or empty value otherwise. For example: `#flag? #param? debug?`
```
-f --debug
```
Result:
```
if [[ ${_flag} == 1 ]]; then
  echo "This will happen!"
fi

if [[ ${_param} == 1 ]]; then
  echo "This will NOT happen!"
fi

if [[ ${_debug} == 1 ]]; then
  echo "This will also happen!"
fi
```