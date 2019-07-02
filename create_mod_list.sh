#! /usr/bin/python3
import os
import json
import xml.etree.ElementTree as etree_read
from lxml import etree

parser = etree.XMLParser(recover=True)

data = {}

def Main():
	global data

	CreateModList(os.getcwd())

	with open('mod_list.json', 'w') as outfile:
		json.dump(data, outfile, indent = 4, ensure_ascii = False)

def CreateModList(path):
	for folder in os.listdir(path):
		FindModXML(path, folder)

def GetXMLValue(data, names):
	for name in names:
		if(data.find(name) != None):
			return data.find(name).text
	return "NA"

def FindModXML(path, folder):
	global data

	mod_name = ""
	mod_id = ""
	mod_version = ""
	mod_author = ""
	mod_thumbnail_path = ""
	mod_description = ""
	mod_directory = ""
	mod_dependencies = ""

	try:
		with open(path + "/" + folder + "/mod.xml") as f:
			print(path + "/" + folder + "/mod.xml")

			tree = etree_read.parse(path + "/" + folder + "/mod.xml", parser=parser)
			root = tree.getroot()

			mod_name = GetXMLValue(root, ["Name"])
			mod_id = GetXMLValue(root, ["Id", "ID"])
			mod_version = GetXMLValue(root, ["Version"])
			mod_author = GetXMLValue(root, ["Author"])
			mod_thumbnail_path = "107.173.129.154/downloader/" + folder + "/" + GetXMLValue(root, ["Thumbnail"])
			mod_description = GetXMLValue(root, ["Description"])
			mod_directory = folder + "/"

			dependency_root = root.find("ModDependency")
			if(dependency_root != None):
				for dependency_id in dependency_root.findall("Id"):
					if mod_dependencies != "":
						mod_dependencies += ","
					mod_dependencies += dependency_id.text

	except IOError:
		return

	data[mod_name] = {"ID" : mod_id, "Name" : mod_name, "Version" : mod_version, "Author" : mod_author, "Thumbnail" : mod_thumbnail_path, "Description" : mod_description, "Directory" : mod_directory, "Dependencies" : mod_dependencies}
	print("Found mod " + mod_id + " " + mod_author + " " + mod_name);

Main()
