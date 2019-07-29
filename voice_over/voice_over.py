#!/usr/bin/env python2.7

import os
# import json
from xml.etree import ElementTree as etree
from lxml import etree
import re
from xml.dom import minidom
import espeak

es = espeak.ESpeak()

es.voice = 'en-scottish'
es.speed = 175
es.word_gap = 5

def walk_error(exception_instance):
	print(exception_instance)

def find_dialogue_txt (path, file_paths):
	# print(path)
	for root, dirs, files in os.walk(path, onerror=walk_error):
		for name in files:
			if name.endswith((".txt")):
				relDir = ""

				fullDir = os.path.realpath(path)
				if root != path:
					relDir = os.path.relpath(root, path)
					fullDir = os.path.join(fullDir, relDir)
				fullDir = os.path.join(fullDir, name)

				# print(relDir)
				# print(fullDir)

				file_info = [fullDir, relDir, name]
				file_paths.append(file_info)

def voice_over_txt(full_level_path, relative_path, file):
	# print(full_level_path)
	with open(full_level_path, "r") as f:
		line = f.readline()
		out_lines = []
		say_counter = 0
		added_lines = 0

		voiceover_path = "Data/VoiceOver"
		dialogue_path = "Data/Dialogues"
		if not os.path.exists(voiceover_path + "/" + relative_path):
			os.makedirs(voiceover_path + "/" + relative_path)
		if not os.path.exists(dialogue_path + "/" + relative_path):
			os.makedirs(dialogue_path + "/" + relative_path)

		while line:
			# Check if line begins with say.
			if line[:3] == "say":
				# Get the text
				split_dialogue = line.split("\"")
				if len(split_dialogue) < 2:
					line = f.readline()
					continue
				dialogue = split_dialogue[3]
				# Remove the [wait 0.2] and split the text.
				split_dialogue = dialogue.split("[")
				dialogue = []
				for dia in split_dialogue:
					second_split_dialogue = dia.split("]")
					if len(second_split_dialogue) > 1:
						dialogue.append(second_split_dialogue[1])
					else:
						# No [ or ] found in this line
						dialogue.append(dia)

				local_path = relative_path
				if local_path != "":
					local_path += "/"

				sound_file = "Data/VoiceOver/" + local_path + file[:-4] + str(say_counter) + ".wav"
				sound_file = sound_file.replace(" ", "_")
				# print(sound_file)
				es.save("".join(dialogue), sound_file)
				out_lines.append("vo \"" + sound_file + "\"\n")
				say_counter += 1
				added_lines += 1
			out_lines.append(line)
			line = f.readline()
		f.close()

		full_dialogue_path = dialogue_path  + "/" + relative_path + "/" + file

		translated_dialogue_file = open(full_dialogue_path,"w")
		for line in out_lines:
		    translated_dialogue_file.write(line)
		translated_dialogue_file.close()

dialogues_path = "/run/HyperDisk/SteamLibraryLinux/steamapps/common/Overgrowth/Data/Dialogues/"

dialogue_info = []
find_dialogue_txt(dialogues_path, dialogue_info)
for info in dialogue_info:
	voice_over_txt(info[0], info[1], info[2])
