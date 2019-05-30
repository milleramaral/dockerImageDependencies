#!/bin/bash

dockerImageDependencies() {
  filterArray() {
    items=( $@ )
    filter=${items[${#items[@]}-1]}
    unset "items[${#items[@]}-1]"

    for item in ${items[@]}; do
      echo $item | grep $filter
    done
  }

  filterDependence() {
    items=( $@ )
    filter=${items[${#items[@]}-1]}
    unset "items[${#items[@]}-1]"

    let index=0

    for item in ${items[@]}; do
      found=`echo $item | grep "^sha256:$filter"`

      if [ ! -z $found ]; then
        found=${found##*sha256:}

        if [ "$filter" != "$found" ]; then
          imageName=`filterArray ${imagesNames[@]} ${found%sha256:*}`

          if [ ! -z $imageName ]; then
            name=${imageName%sha256:*}
            id=${imageName##*sha256:}
            echo "  |- "$name" - "$id
          fi

          newList=( ${items[@]})
          unset newList[$index]
          filterDependence ${newList[@]} $found
        fi
      fi

      let "index++"
    done
  }

  imagesNames=(`docker images --format="{{.Repository}}:{{.Tag}}{{.ID}}" --no-trunc `)
  parentList=(` docker inspect --format='{{.Id}}{{.Parent}}' $(docker images --all --quiet) `)
  if [ -z $1 ]; then
    lists=`docker image ls --quiet`
  else
    lists=`docker image ls --quiet --no-trunc | grep -o "$1"`
    echo $lists
  fi

  for image in $lists; do
    imageFilter=$image
    result=`filterArray ${imagesNames[@]} "$imageFilter"`
    echo -e "\033[1;49;33m|-"${result%sha256:*} - ${result##*sha256:}"\033[0m"

    filterDependence ${parentList[@]} $imageFilter
    echo
  done
}

dockerImageDependencies $1