#!/bin/bash
echo "Preparing to make and save movies"

##################################################
# CONSTANTS
PERF_GUARANTEE=1.0
##################################################

# save this so we can find visualizer_rllib.py
script_path=$(pwd)

# source shflags
. $script_path/../flow/utils/shflags

# define a 'name' command-line string flag
DEFINE_string 'checkpoint_path' 'no_flag' 'path to outer folder with pkl files' 'fc'
DEFINE_boolean 'bm_mode' false 'whether to check if benchmarks satisfy metrics' 'bm'

# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

# check if a path to the checkpoints was passed
file_path=
if [ "${FLAGS_checkpoint_path}" == 'no_flag' ]; then
    echo "Please pass the path to the outer folder containing benchmarks"
    exit 1
fi

cd "${FLAGS_checkpoint_path}"

# create an array containing the benchmark names and expected metrics
declare -a benchmarks=(
                        "bottleneck0" "bottleneck1" "bottleneck2"
                        "figureeight0" "figureeight1" "figureeight2"
                        "grid0" "grid1"
                        "merge0" "merge1" "merge2"
                        )


# step into every pulled folder
for outer_folder in */; do
    cd $outer_folder
    for inner_folder in */; do
        cd $inner_folder
        checkpoint_num="$(ls | grep '^checkpoint_[0-9]\+$' | cut -c12- | sort -n | tail -n1)"
        echo "====================================================================="
        echo "Visualizing highest checkpoints in "$outer_folder
        echo "====================================================================="
        file_path=$(pwd)

        # if you want to evaluate the benchmarks
        if ${FLAGS_bm_mode}; then
            python $script_path/../flow/visualize/visualizer_rllib.py $file_path $checkpoint_num \
            --save_render --num_rollouts 5> $script_path/tmp.txt
            # read out the text file to find the avg velocity and avg outflow
            speed_str=$(grep "Average, std speed" $script_path/tmp.txt)
            outflow_str=$(grep "Average, std  outflow" $script_path/tmp.txt)
            rew_str=$(grep "Average, std return:" $script_path/tmp.txt)
            # parse the speed and outflow from the string
            IFS=' ' read -ra speed_arr <<< "$speed_str"
            speed=${speed_arr[3]}
            IFS=' ' read -ra outflow_arr <<< "$outflow_str"
            outflow=${outflow_arr[3]}
            IFS=' ' read -ra rew_arr <<< "$rew_str"
            rew=${outflow_arr[3]}
            unset IFS
            # now figure out whether benchmark should be evaluated by speed or
            # by outflow

            # benchmarks with outflow rewards
            if $outer_folder == "bottleneck0" or $outer_folder == "bottleneck1"\
            or $outer_folder == "bottleneck2"; then
                if $outer_folder == "bottleneck0"; then
                    if $outflow/1167.0 lt $PERF_GUARANTEE; then
                        echo "bottleneck 0 underperformed"
                        exit 1
                    fi
                elif $outer_folder == "bottleneck1"; then
                    if $outflow/1258.0 lt $PERF_GUARANTEE; then
                        echo "bottleneck 1 underperformed"
                        exit 1
                    fi
                elif $outer_folder == "bottleneck2"; then
                    if $outflow/2143.0 lt $PERF_GUARANTEE; then
                        echo "bottleneck 2 underperformed"
                        exit 1
                    fi
                fi

            # benchmarks with speed rewards
            elif $outer_folder == "figureeight0" or $outer_folder == "figureeight1" \
            or $outer_folder == "figureeight2" or $outer_folder == "merge0" \
            or $outer_folder == "merge1" or $outer_folder == "merge2"; then
                if $outer_folder == "figureeight0"; then
                    if $speed/7.3 lt $PERF_GUARANTEE; then
                        echo "figureeight 0 underperformed"
                        exit 1
                    fi
                elif $outer_folder == "figureeight1"; then
                    if $speed/6.4 lt $PERF_GUARANTEE; then
                        echo "figureeight 1 underperformed"
                        exit 1
                    fi
                elif $outer_folder == "figureeight2"; then
                    if $speed/5.7 lt $PERF_GUARANTEE; then
                        echo "figureeight 2 underperformed"
                        exit 1
                    fi
                elif $outer_folder == "merge0"; then
                    if $speed/13.0 lt $PERF_GUARANTEE; then
                        echo "merge 0 underperformed"
                        exit 1
                    fi
                elif $outer_folder == "merge1"; then
                    if $speed/13.0 lt $PERF_GUARANTEE; then
                        echo "merge 1 underperformed"
                        exit 1
                    fi
                elif $outer_folder == "merge2"; then
                    if $speed/13.0 lt $PERF_GUARANTEE; then
                        echo "merge 2 underperformed"
                        exit 1
                    fi
                fi
            # benchmarks that use the reward as their metric
            else
                if $outer_folder == "grid0"; then
                    if rew/296.0 lt 0.97; then
                        echo "grid 0 underperformed"
                        exit 1
                    fi
                elif $outer_folder == "grid1"; then
                    if rew/296.0 lt 0.97; then
                        echo "grid 1 underperformed"
                        exit 1
                    fi
                fi
            fi


        else
            python $script_path/../flow/visualize/visualizer_rllib.py $file_path $checkpoint_num \
            --save_render
        fi
        cd "../"
    done
    cd "../"
done
