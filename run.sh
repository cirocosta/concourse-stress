#!/bin/bash

set -o errexit
set -o xtrace

readonly PREFIX=${PREFIX:-"test"}

main () {
	case $1 in
		trigger)
			trigger_jobs $2
			;;

		set)
			set_pipelines $2
			;;

		pause)
			pause_pipelines
			;;

		unpause)
			unpause_pipelines
			;;

		destroy)
			destroy_pipelines
			;;

		*)
			echo "usage: (trigger|set|destroy)"
			exit 1
			;;
	esac
}

destroy_pipelines () {
	fly -t local pipelines | \
		awk '{print $1}' | xargs -n1 -P10 \
			fly -t local dp -n -p
}

pause_pipelines () {
	fly -t local pipelines | \
		awk '{print $1}' | xargs -n1 -P10 \
			fly -t local pause-pipeline -p
}

unpause_pipelines () {
	fly -t local pipelines | \
		awk '{print $1}' | xargs -n1 -P10 \
			fly -t local unpause-pipeline -p
}

set_pipelines () {
	local n=$1

	seq 1 $n | \
		xargs -P36 -I{} \
			fly -t local set-pipeline -n -p $PREFIX-{} -c pipeline.yml

	seq 1 $n | \
		xargs -P36 -I{} \
			fly -t local unpause-pipeline -p $PREFIX-{}
}

trigger_jobs () {
	local n=$1
	local jobs=$(fly -t local jobs -p $PREFIX-1 | awk '{print $1}')

	for i in $(seq $n); do
		echo "$jobs" | xargs -P20 -I[] fly -t local trigger-job -j $PREFIX-$i/[]
	done
}

main "$@"
