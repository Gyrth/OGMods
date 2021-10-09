#!/bin/bash
for file in *; do
	if [ ${file: -4} == ".ogg" ]
	then
		filename="${file}"
		extention=".wav"
		new_file_name="${file/.ogg/"$extention"}"
		echo $new_file_name
		ffmpeg -i $filename -acodec pcm_s16le -ac 1 -ar 44100 "output_$new_file_name"
		# rm $filename
		mv "output_$new_file_name" $new_file_name
	fi
done
