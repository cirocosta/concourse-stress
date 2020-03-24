#!/bin/bash

set -o errexit
set -o nounset


main () {
	login

	for iter in $(seq 1 20); do
		make_all_jobs_active

		for i in $(seq 1 28); do
			echo "ITER: $iter $i ----------"

			reduce_jobs "1000"
			gc
			time_taken=$(request_jobs)

			printf "%s,%s,%s,%s\n" $iter $i $(mem) $time_taken >> results.txt
		done
	done
}

reduce_jobs () {
	local amount=$1
	local qry="UPDATE jobs SET active=false WHERE CTID IN (select CTID from jobs where active is true limit $amount);"

	echo "$qry" | docker exec -i concourse_db_1 psql -U dev --dbname concourse;
}

make_all_jobs_active () {
	local qry="UPDATE jobs SET active=true;"

	echo "$qry" | docker exec -i concourse_db_1 psql -U dev --dbname concourse;
}

login () {
	fly -t local login -u test -p test
}

request_jobs () {
	local start=$(date +%s)
	fly -t local curl /api/v1/jobs &> /dev/null
	local end=$(date +%s)

	echo $((end-start))
}

gc () {
	curl localhost:8079/debug/gc
}

mem () {
	curl localhost:8079/debug/mem
}

main
