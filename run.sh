#!/bin/bash

set -o errexit
set -o xtrace

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

set_pipelines () {
	local n=$1

	seq 1 $n | \
		xargs -P36 -I{} \
			fly -t local set-pipeline -n -p test-{} -c pipeline.yml
}

trigger_jobs () {
	local n=$1
	local jobs=$(fly -t local jobs -p test-1 | awk '{print $1}')

	for i in $(seq $n); do
		fly -t local unpause-pipeline -p test-$i
		echo "$jobs" | xargs -P20 -I[] fly -t local trigger-job -j test-$i/[] -w
		fly -t local pause-pipeline -p test-$i
	done
}

main "$@"
