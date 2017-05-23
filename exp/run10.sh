#!/bin/bash
root=~/github/Corblivar
base=$root/exp
fitting=thermal_analysis_octave

exp=$1
benches=$2
runs=20
wait_for_octave=30

for die_count in 2 3 4
#for die_count in $2
do
	dies=$die_count"dies"

	# switch to experiments folder; create if required

	cd $base

	if [ ! -d "$dies" ]; then
		mkdir $dies
	fi

	cd $dies

	if [ ! -d "$exp" ]; then
		mkdir $exp
	fi

	cd $exp

	# init experiments, if required
	#

	# HotSpot, thermal fitting related
	cp -r $root/$fitting .
	cp $base/hotspot*.config $fitting/
	cp $base/HotSpot.sh .
	ln -s $base/benches .
	cp $base/gp.sh .

	# local copy of config files
	for bench in $benches
	do
		cp $base/configs/$dies/$exp/*.conf* .
	done

	cd $fitting

	for bench in $benches
	do
		# only proceed in case no other octave instance is still running, as the script does not cope well with that
		# note that 1 process will always be there, which is the grep process
		while [[ `ps aux | grep 'octave optimization.m' | wc -l` > 1 ]]
		do
			echo "another instance of 'octave optimization.m' is still running: `ps aux | grep 'octave optimization.m' | head -n 1`"
			echo "retrying in $wait_for_octave ..."
			sleep $wait_for_octave
		done

		# (TODO) provide 0(%) as further, final parameter to ignore all TSVs; provide any other number to override actual TSVs with regular TSV structure of given density,
# ranging from 0 to 100(%)
		octave optimization.m $bench $base/$dies/$exp/$bench.conf $root
	done

	cd $base/$dies/$exp

	# init experiments done
	#

	for (( run = 1; run <= $runs; run++ ))
	do

		if [ ! -d "$run" ]; then
			mkdir $run
		fi

		cd $run

		#
		# we reached the experiments folder
		#

		# copy aux scripts
		cp $base/gp.sh .
		cp $base/clean.sh .
		cp $base/HotSpot.sh .
		cp $base/hotspot*.config .

		# perform experiments; run Corblivar for each benchmark
		for bench in $benches
		do
			dir=`pwd`

			echo "running Corblivar for $bench on $dies; run $run; working dir: $dir"

			# use local config; configured w/ thermal fitting
			# also wrap gdb in batch mode, which helps to log any segfault's origin
			gdb -batch -ex=run -ex=backtrace --args $root/Corblivar $bench $base/$dies/$exp/$bench.conf $base/benches/ > $bench.log

			# run individual aux scripts, if required
			#
			./HotSpot.sh $bench $die_count

#			# evaluate leakage via dedicated binary
#			$root/Correlation_TSC $bench $base/$dies/$exp/$bench.conf $base/benches/ $bench.solution >> $bench.log
		done

		# run experiments-folder aux scripts
		./gp.sh

		cd $base/$dies/$exp

	done
done
