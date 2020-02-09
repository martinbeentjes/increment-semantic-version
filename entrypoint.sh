#!/bin/bash -l

# active bash options:
#   - stops the execution of the shell script whenever there are any errors from a command or pipeline (-e)
#   - option to treat unset variables as an error and exit immediately (-u)
#   - print each command before executing it (-x)
#   - sets the exit code of a pipeline to that of the rightmost command
#     to exit with a non-zero status, or to zero if all commands of the
#     pipeline exit successfully (-o pipefail)
set -euo pipefail

configure_pre_postfix() {  
  pre="-alpha-${GITHUB_SHA::8}"
}

bump_version() {
  case "$release_type" in
    "major")
      ((++major)); minor=0; patch=0; pre="";;
    "minor")
      ((++minor)); patch=0; pre="";;
    "patch")
      ((++patch)); pre="";;
  esac
}

main() {
  echo "amount of args is $#"
  if [[ "$#" -lt 3 ]]; then
    echo "Must have two or three arguments: previous_version release_type [alpha_build, if alpha is requested]"; exit 1
  fi
  prev_version="$1"; release_type="$2"; 

  if [[ "$prev_version" == "" ]]; then
    echo "Could not read previous version"; exit 1
  fi

  possible_release_types="major minor patch"

  if [[ ! ${possible_release_types[*]} =~ ${release_type} ]]; then
    echo "Invalid argument for release_type! Valid arguments are: [ ${possible_release_types[*]} ]"; exit 1
  fi

  major=0; minor=0; patch=0; pre=""; preversion=0

  # break down the version number into it's components
  regex="^([0-9]+).([0-9]+).([0-9]+)((-[a-z]+-)([0-9]+))?$"
  if [[ $prev_version =~ $regex ]]; then
    major="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    patch="${BASH_REMATCH[3]}"
    pre="${BASH_REMATCH[5]}"
    preversion="${BASH_REMATCH[6]}"
  else
    echo "previous version '$prev_version' is not a semantic version"
    exit 1
  fi

  bump_version
  if [[ $# -eq 3 ]]; then
    configure_pre_postfix
  fi

  next_version="${major}.${minor}.${patch}${pre}"
  echo "create $release_type-release version: $prev_version -> $next_version"
  echo ::set-output name=next-version::"$next_version"
}

main "$@"