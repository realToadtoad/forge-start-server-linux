#!/bin/env bash

# display code based on https://askubuntu.com/a/691237/590804, by chaos, under creative commons by-sa 3.0 (https://creativecommons.org/licenses/by-sa/3.0/)
base64 -d <<<"H4sIAAAAAAAAA4WPwQnAMAwD/5pCAxS0UMDdf4rYIo+2NlSBM5ydBJPh8JPJlQUVVeW+p3xfzHNeelmQ7qXgMm/TZrI484qRzRJVufxf8npQ3eYW6Iv9BBu69ftHJwEAAA==" | gunzip

if test -e start-server-settings.txt; then
  n="$(cat start-server-settings.txt | head -n 1)"
  mB="$(cat start-server-settings.txt | head -n 2 | tail -n 1)"
  jarLoc="$(cat start-server-settings.txt | head -n 3 | tail -n 1)"
  z="$(cat start-server-settings.txt | head -n 4 | tail -n 1)"
fi

# code for argument parsing from https://stackoverflow.com/a/29754866/6741464, by robert siemer, under creative commons by-sa 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)

set -o errexit -o pipefail -o noclobber -o nounset
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'Error: `getopt --test` failed in this environment.'
    exit 1
fi
OPTIONS=hsnm:j:z
LONGOPTS=help,save-options,no-backup,megabytes:,jar:,force-zip
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi
eval set -- "$PARSED"
s=n n=n mB=- jarLoc=- zip=n h=n

while true; do
    case "$1" in
        -h|--help)
            h=y
            shift
            ;;
        -s|--save-options)
            s=y
            shift
            ;;
        -n|--no-backup)
            n=y
            shift
            ;;
        -m|--megabytes)
            mB="$2"
            shift 2
            ;;
        -j|--jar)
            jarLoc="$2"
            shift 2
            ;;
        -z|--force-zip)
            zip=y
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Error: Faulty input"
            exit 3
            ;;
    esac
done

if [ $h == y ]; then
  base64 -d <<<"H4sIAAAAAAAAA21STU/kMAy991f4uCsm6REJiQMgkJAYQMNwQnvwNO40bCaO4nRY5tdv3M4u7EelSont9/z84mfBLZ2BbaVgLkYo7ylbGeDl4XF9+3D/zVrbPGkOlj5Sl7EvMFcBRgddJiwEG+y+j0ksfLlar+5OrqAwdIGFjrX2a9MAmGEBxgwUEvzvc15SwHfgVDxHUYAoQHBP5hj8A6AJGIXcL4i2Reh9ID3VDKCAox7HUJQuKl1kM8v9u/+bDwEil+M0UAaCN87BTYyTnh3cPy8vr1fKs6Mtbt4Lyfkcq3qoTKA47jbVH+7hd41eVhdLlZUy772jDz+V+BVubu+ulfYV87mePyvTSaZYhecxfkAXOiCnxGpCTWr3UB9ECtxw3hJU76U6Az2P9bV8nCp6Do6ytj1ox55zR+bg/zFE22rYRymETmc4PVR/OUPHu5RJlHsBuU6ZXbVIwM8lXiYQhkCuaS7n7QDMNL3ZJNW2x6Vpm2YoJclZ2259GcaNreRt3auwZnSl/m2vs5jPK2qCj+OP5ifw9L4IvwIAAA==" | gunzip
  exit 0
fi

if ! [ -x "$(command -v java)" ]; then
  echo 'Error: java is not installed. Aborting.' >&2
  exit 4
fi

if [ $n != y ]; then
  SEVENZ_INSTALLED=1
  if ! [ -x "$(command -v 7za)" ]; then
    echo 'Warning: 7za is not installed. Falling back to zip.' >&2
    SEVENZ_INSTALLED=0
  fi
fi

FORGE="$(ls -r | grep forge.*universal\.jar | head -n 1)"

if [ $jarLoc != "-" ]; then
  if [ ${jarLoc: -4} != ".jar" ]; then
    echo "Warning: $jarLoc is not a jar file. Falling back to default."
  else
    FORGE=$jarLoc
  fi
fi

RAM=4096

if [ $mB != "-" ]; then
  re='^[0-9]+$'
  if ! [[ $mB =~ $re ]]; then
    echo "Warning: $mB is not a number. Falling back to default."
  else
    if [$mB < 4096]; then
      echo "Warning: $mB is a relatively low amount of RAM. Consider increasing the amount if possible."
    fi
    RAM=$mB
  fi
fi

# ctrl+c trapping based on https://stackoverflow.com/a/29754866/6741464, by robert siemer, under creative commons by-sa 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)

exit_stuff() {
  echo "server stopped"

  CURR_TIME="$(date --rfc-3339=seconds)"
  if [ $n != y ]; then
    if [ $SEVENZ_INSTALLED == 1 ]; then
      echo $zip
      if [ $zip == n ]; then
        7za a "backups/$CURR_TIME.7z" world -r
      else
        zip "backups/$CURR_TIME.zip" world -r
      fi
    else
      zip "backups/$CURR_TIME.zip" world -r
    fi
  else
    echo "Warning: backups are disabled."
  fi

  if [ $s == "y" ]; then
    echo "Saving settings..."
    printf "$n\n$mB\n$jarLoc" > start-server-settings.txt
  fi
  
  printf "\nExiting..."
  exit 0
}

trap 'exit_stuff' SIGINT
  
java -Xmx"$RAM"M -Xms"$RAM"M -jar $FORGE nogui
