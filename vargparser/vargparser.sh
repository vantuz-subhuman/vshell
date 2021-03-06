#!/usr/bin/env bash

VARGPARSER_ARG_VAR_PREFIX="vargparser_dynamic_arg_var_"

vargparser_pattern="$1"
vargparser_required_arguments=()
for word in ${vargparser_pattern}; do
  vargparser_arg_required=`[[ ${word} == '^'* ]] && echo 1 || echo 0`;
  if [[ ${vargparser_arg_required} == 1 ]]; then
    word=${word:1};
    if [[ ! ${word} ]]; then
      (>&2 echo "Argument pattern cannot end at '^'!");
      exit 1;
    fi
  fi
  vargparser_arg_short_flag=`[[ ${word} == '#'* ]] && echo 1 || echo 0`;
  if [[ ${vargparser_arg_short_flag} == 1 ]]; then
    word=${word:1};
    if [[ ! ${word} ]]; then
      (>&2 echo "Argument pattern cannot end at '#'!");
      exit 1;
    fi
  fi
  vargparser_arg_boolean=`[[ ${word} == *'?' ]] && echo 1 || echo 0`;
  if [[ ${vargparser_arg_boolean} == 1 ]]; then
    word=${word:0:(${#word}-1)};
    if [[ ! ${word} ]]; then
      (>&2 echo "Argument is required to have a name before '?'!");
      exit 1;
    fi
  fi
  if [[ ! ${word} =~ ^[[:alpha:][:digit:]-]+$ ]]; then
    (>&2 echo "Argument name may only consist of letters or numbers or dash! Found: '${word}'");
    exit 1;
  fi
  if [[ ${#word} == 1 ]]; then
    (>&2 echo \
"Argument required to have name longer than a single letter!
Use '#' in order to create an *additional* short flag");
    exit 1;
  fi
  vargparser_arg_var_full_name="${VARGPARSER_ARG_VAR_PREFIX}${word//-/_}";
  if [[ ${!vargparser_arg_var_full_name} ]]; then
    (>&2 echo "Two arguments cannot have the same name! Found: '${word}'");
    exit 1;
  fi
  vargparser_arg_public_form="--${word}"
  if [[ ${vargparser_arg_short_flag} == 1 ]]; then
    vargparser_arg_var_short_name="${VARGPARSER_ARG_VAR_PREFIX}${word:0:1}";
    vargparser_arg_public_form="(-${word:0:1}|${vargparser_arg_public_form})"
    if [[ ${!vargparser_arg_var_short_name} ]]; then
      (>&2 echo "Two short arguments cannot start with the same letter! Found: '${word}'");
      exit 1;
    fi
  fi
  if [[ ${vargparser_arg_boolean} != 1 ]]; then
    vargparser_arg_public_form="${vargparser_arg_public_form} <value>"
  fi
  if [[ ${vargparser_arg_required} == 1 ]]; then
    vargparser_required_arguments+=("${word};${vargparser_arg_public_form};")
  fi
  vargparser_arg_var_value="\"${word};${vargparser_arg_boolean}\"";
  eval `echo "${vargparser_arg_var_full_name}=${vargparser_arg_var_value}"`;
  if [[ ${vargparser_arg_short_flag} == 1 ]]; then
    eval `echo "${vargparser_arg_var_short_name}=${vargparser_arg_var_value}"`;
  fi
done
shift;
while [[ $# -gt 0 ]]; do
  vargparser_arg_definition=;
  if [[ "$1" =~ ^-(.)$ || "$1" =~ ^--([[:alpha:][:digit:]-]{2,})$ ]]; then
    vargparser_arg_var_name="${VARGPARSER_ARG_VAR_PREFIX}${BASH_REMATCH[1]//-/_}"
    IFS=';' read -ra vargparser_arg_definition <<< "${!vargparser_arg_var_name}"
  fi
  if [[ ! ${vargparser_arg_definition} ]]; then
    (>&2 echo "Unexpected argument: '$1'!");
    exit 1;
  fi
  vargparser_arg_full_name=${vargparser_arg_definition[0]};
  vargparser_arg_boolean=${vargparser_arg_definition[1]};
  f="${vargparser_arg_full_name}\;*\;"
  q=${vargparser_required_arguments[@]#${f}}
  vargparser_required_arguments=("${q[@]}");
  if [[ ${vargparser_arg_boolean} == 1 ]]; then
    eval `echo "_${vargparser_arg_full_name//-/_}=1"`
  else
    if [[ ! "$2" ]]; then
      (>&2 echo "Argument '$1' requires a value!");
      exit 1;
    fi
    eval `echo "_${vargparser_arg_full_name//-/_}=\"$2\""`
    shift;
  fi
  shift;
done
if [[ ${vargparser_required_arguments[@]} ]]; then
  msg="These arguments are required:"
  for a in "${vargparser_required_arguments[@]}"; do
    IFS=';' read -ra arr <<< "${a}"
    msg="${msg}\n${arr[1]}"
  done
  (>&2 echo -e ${msg});
  exit 1;
fi
