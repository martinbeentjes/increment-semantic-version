#!/bin/bash -l

# active bash options:
#   - stops the execution of the shell script whenever there are any errors from a command or pipeline (-e)
#   - option to treat unset variables as an error and exit immediately (-u)
#   - print each command before executing it (-x)
#   - sets the exit code of a pipeline to that of the rightmost command
#     to exit with a non-zero status, or to zero if all commands of the
#     pipeline exit successfully (-o pipefail)
set -euo pipefail

main() {

  prev_version="$1"
  
  release_type="$2" 
  
  use_commit="$3"
  
  if [[ ! -z "$use_commit" ]]; then
    use_commit="no"
  else 
    use_commit="$(echo $3 | tr '[A-Z]' '[a-z]')"
    if [[ $use_commit != "yes" ]]; then
      use_commit="no"
    fi
  fi

  if [[ "$prev_version" == "" ]]; then
    echo "could not read previous version"; exit 1
  fi

  possible_release_types="major feature bug alpha beta rc"

  if [[ ! ${possible_release_types[*]} =~ ${release_type} ]]; then
    echo "valid argument: [ ${possible_release_types[*]} ]"; exit 1
  fi

  major=0; minor=0; patch=0; pre=""; preversion=0

  # break down the version number into it's components
  regex="^([0-9]+).([0-9]+).([0-9]+)((-[a-z]+)([0-9]+))?$"
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

  # increment version number based on given release type
  case "$release_type" in
  "major")
    ((++major)); minor=0; patch=0; pre="";;
  "feature")
    ((++minor)); patch=0; pre="";;
  "bug")
    ((++patch)); pre="";;
  "alpha")
    if [[ "$use_commit" == "yes" ]]; then
      preversion="${GITHUB_SHA::8}"
    else
      if [[ ! -z "$preversion" ]]; then
        preversion=0
      fi
      ((++preversion))
      if [[ "$pre" != "-alpha" ]]; then
        preversion=1
      fi
    fi
    pre="-alpha$preversion";;
  "beta")
    if [[ "$use_commit" == "yes" ]]; then
      preversion="${GITHUB_SHA::8}"
    else
      if [[ ! -z "$preversion" ]]; then
        preversion=0
      fi
      ((++preversion))
      if [[ "$pre" != "-beta" ]]; then
        preversion=1
      fi
    fi
    pre="-beta$preversion";;
  "rc")
    if [[ "$use_commit" == "yes" ]]; then
      preversion="${GITHUB_SHA::8}"
    else
      if [[ ! -z "$preversion" ]]; then
        preversion=0
      fi
      ((++preversion))
      if [[ "$pre" != "-rc" ]]; then
        preversion=1
      fi
    fi
    pre="-rc$preversion";;
  esac

  next_version="${major}.${minor}.${patch}${pre}"
  echo "create $release_type-release version: $prev_version -> $next_version"

  echo ::set-output name=next-version::"$next_version"
}

main "$1" "$2"
