#!/bin/bash

HS=~/code/HotSpot

if [ "$1" == "" ]; then
	echo "Provide benchmark name as parameter!"
	exit
fi

if [ "$2" == "" ]; then
	echo "Provide layer count!"
	exit
fi

DUMMY_FP=$1_HotSpot_Si_active_1.flp
PTRACE=$1_HotSpot.ptrace
GRID_LCF=$1_HotSpot.lcf
STEADY_OUTPUT=$1_HotSpot.steady
STEADY_GRID_OUTPUT=$1_HotSpot.steady.grid
LOG=$1_HotSpot.txt
CONFIG=hotspot_heatsink.config

# perform HS call
echo "Perform HotSpot run ..."
echo "$HS/hotspot -c $CONFIG -f $DUMMY_FP -p $PTRACE -grid_steady_file $STEADY_GRID_OUTPUT -steady_file $STEADY_OUTPUT -detailed_3D on -grid_layer_file $GRID_LCF > $LOG"
time $HS/hotspot -c $CONFIG -f $DUMMY_FP -p $PTRACE -grid_steady_file $STEADY_GRID_OUTPUT -steady_file $STEADY_OUTPUT -detailed_3D on -grid_layer_file $GRID_LCF > $LOG
STATUS=$?

if [ "$STATUS" == "0" ]; then

# log hottest block
	tail -n1 $LOG

# render temperature maps using gnuplot script generated by Corblivar
	for (( die = 1; die <= $2; die++ ))
	do
		echo "Render gp temperature map for die $die"

		gnuplot $1"_"$die"_HotSpot.gp"
	done
fi
