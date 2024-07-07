#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -i <input_folder> -o <output_folder>"
    exit 1
}

# Parse command line options using getopts
while getopts ":i:o:" opt; do
    case $opt in
        i) input_folder="$OPTARG" ;;
        o) output_folder="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if all required options are provided
if [ -z "$input_folder" ] || [ -z "$output_folder" ]; then
    usage
fi

# Function to extract frames from videos
extract_frames() {
    local input_folder="$1"
    local output_folder="$2"

    # Loop through each video file in the directory
    for VIDEO_FILE in "$input_folder"/*.mp4; do
        # Get the base name of the video file (without the directory and extension)
        local BASE_NAME=$(basename "$VIDEO_FILE" .mp4)

        # Create a directory for the frames of this video
        mkdir -p "$output_folder/$BASE_NAME"

        # Run ffmpeg to extract frames
        ffmpeg -y -vsync 0 -hwaccel cuda -i "$VIDEO_FILE" -vf scale=360:640 -qscale:v 1 "$output_folder/$BASE_NAME/frame_%04d.jpg"
    done
}

# Call the function with the provided arguments
extract_frames "$input_folder" "$output_folder"
