#!/bin/bash -l

# active bash options:
#   - stops the execution of the shell script whenever there are any errors from a command or pipeline (-e)
#   - option to treat unset variables as an error and exit immediately (-u)
#   - print each command before executing it (-x)
#   - sets the exit code of a pipeline to that of the rightmost command
#     to exit with a non-zero status, or to zero if all commands of the
#     pipeline exit successfully (-o pipefail)
set -euo pipefail

configure_postfix() {
  if [[ ! -z "$preversion" ]]; then
    ((++preversion))
  else 
    preversion=1
  fi 
  pre="-alpha-$preversion"
}

bump_version() {
  case "$release_type" in
    "major")
      ((++major)); minor=0; patch=0; pre="";;
    "minor")
      ((++minor)); patch=0; pre="";;
    "patch")
      ((++patch)); pre="";;
    "prerelease")
      if [[  -z "$pre" ]]; then # if pre is not empty
         ((++minor)); # increment
         patch=0 # set patch to zero
      fi;;
  esac
}

main() {
  if [[ "$#" -ne 2 ]]; then
    echo "Must have two arguments: previous_version release_type"; exit 1
  fi

  prev_version="$1"; release_type="$2";

  if [[ "$prev_version" == "" ]]; then
    echo "could not read previous version"; exit 1
  fi

  possible_release_types="major minor patch prerelease"

  if [[ ! ${possible_release_types[*]} =~ ${release_type} ]]; then
    echo "valid argument: [ ${possible_release_types[*]} ]"; exit 1
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

  # 0.1.0 prerelease should result in 0.2.0-alpha-1 (or patch? what... FUCK)
  if [[ "$release_type" == "prerelease" ]]; then
    
    
    # pre_backup=pre
    bump_version

    # pre=pre_backup
    configure_postfix 
  else
    bump_version
  fi

  next_version="${major}.${minor}.${patch}${pre}"
  echo "create $release_type-release version: $prev_version -> $next_version"

  echo ::set-output name=next-version::"$next_version"
}

main "$@"