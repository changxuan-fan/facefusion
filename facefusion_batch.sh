#!/bin/bash

run_processing() {
    local input_folder="$1"
    local output_folder="$2"
    local face_img="$3"

    # Create the output folder if it doesn't exist
    mkdir -p "$output_folder"

    # Record the start time
    local start_time=$(date +%s)

    # Get the number of available GPUs
    local NUM_GPUS=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)

    # Get the list of MP4 files in the input folder
    local video_files=("$input_folder"/*.mp4)

    # Function to run a command on a specific GPU
    run_command() {
        local gpu_id=$1
        local video=$2
        local output_video=$3
        CUDA_VISIBLE_DEVICES=$gpu_id python run.py -t "$video" -s "$face_img" -o "$output_video" --face-mask-types region --face-mask-blur 0.8 --face-mask-regions skin
    }

    # Initialize an array to track GPU availability
    declare -a gpu_available
    for ((i=0; i<NUM_GPUS; i++)); do
        gpu_available[i]=1
    done

    # Initialize an array to hold PIDs for background processes
    declare -a gpu_pids

    # Process each video file
    for video in "${video_files[@]}"; do
        local video_filename=$(basename "$video")
        local output_video="$output_folder/$video_filename"

        while : ; do
            for ((i=0; i<NUM_GPUS; i++)); do
                if [[ ${gpu_available[i]} -eq 1 ]]; then
                    gpu_available[i]=0
                    run_command $i "$video" "$output_video" &
                    gpu_pids[i]=$!
                    break 2
                fi
            done
            # Check if any GPU has finished its task
            for ((i=0; i<NUM_GPUS; i++)); do
                if [[ -n "${gpu_pids[i]}" && ! -e /proc/${gpu_pids[i]} ]]; then
                    gpu_available[i]=1
                fi
            done
            sleep 1
        done
    done

    # Wait for all background processes to complete
    wait

    # Display the total execution time in a human-readable format
    local end_time=$(date +%s)
    local execution_time=$((end_time - start_time))
    local hours=$((execution_time / 3600))
    local minutes=$(( (execution_time % 3600) / 60 ))
    local seconds=$((execution_time % 60))
    echo "Total execution time: ${hours}h ${minutes}m ${seconds}s"
}

# Call the function with input folder, output folder, and face image path
run_processing "inputs" "results" "face_food_eating.webp"
