#! /usr/bin/python3
import os
import json
import xml.etree.ElementTree as etree
from lxml import etree

main_path = "/run/HyperDisk/SteamLibraryLinux/steamapps/common/Overgrowth/"
custom_animations_path = "/run/HyperDisk/SteamLibraryLinux/steamapps/workshop/content/25000/"

index = 0
root_element = etree.Element('root')
data = {}

def Main():
	global data

	CreateModList(os.getcwd())

	with open('mod_list.json', 'w') as outfile:
		json.dump(data, outfile, indent = 4, ensure_ascii = False)

def CreateModList(path):
	for folder in os.listdir(path):
		FindModXML(path, folder)

def FindModXML(path, folder):
	global data

	mod_name = ""
	mod_id = ""
	mod_version = ""
	mod_author = ""
	mod_thumbnail_path = ""
	mod_description = ""

	print(path + "/" + folder + "/mod.xml")

	try:
		with open(path + "/" + folder + "/mod.xml") as f:
			lines = f.readlines()
			for line in lines:
				if "<Name>" in line:
					line = line.replace("<Name>", "");
					line = line.replace("</Name>", "");
					mod_name = (' '.join(line.split()));
				elif "<Id>" in line:
					line = line.replace("<Id>", "");
					line = line.replace("</Id>", "");
					mod_id = (' '.join(line.split()));
				elif "<Version>" in line:
					line = line.replace("<Version>", "");
					line = line.replace("</Version>", "");
					mod_version = (' '.join(line.split()));
				elif "<Author>" in line:
					line = line.replace("<Author>", "");
					line = line.replace("</Author>", "");
					mod_author = (' '.join(line.split()));
				elif "<Thumbnail>" in line:
					line = line.replace("<Thumbnail>", "");
					line = line.replace("</Thumbnail>", "");
					mod_thumbnail_path = folder + "/" + (' '.join(line.split()));
				elif "<Description>" in line:
					line = line.replace("<Description>", "");
					line = line.replace("</Description>", "");
					mod_description = (' '.join(line.split()));
	except IOError:
		return

	data[mod_name] = {"ID" : mod_id, "Name" : mod_name, "Version" : mod_version, "Author" : mod_author, "Thumbnail" : mod_thumbnail_path, "Description" : mod_description}
	print("Found mod " + mod_id + " " + mod_author + " " + mod_name);

Main()
