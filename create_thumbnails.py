#! /usr/bin/python3.9
import os
import json
import xml.etree.ElementTree as etree
from lxml import etree
from PIL import Image

screenshot_json_path = "/home/gyrth/.local/share/Overgrowth/screenshot_data.json"
screenshots_path = "/home/gyrth/.local/share/Overgrowth/Screenshots/"
install_path = "/home/gyrth/.local/share/Steam/steamapps/common/Overgrowth/"

index = 0
root_element = etree.Element('root')
data = {}
item_list = {}

def write_json():
	global data
	global item_list

	data["item_list"] = item_list
	print("Total items found " + str(len(item_list)));
	# print json.dumps(data, indent=4)
	with open('spawner/Data/Scripts/thumbnail_database.json', 'w') as outfile:
		json.dump(data, outfile, indent = 4, ensure_ascii = False)

def read_thumbnail_json(path):
	with open(path) as f:
		data = json.load(f)

	#Make sure the directory or path exists or else writing to it isn't going to work.
	directory = "spawner/Data/UI/spawner/thumbs/extra/"
	if not os.path.exists(directory):
		os.makedirs(directory)

	for value in data["screenshot_links"]:
		object_path = value
		split_text = value.split("/")
		#Get the name of the object from the path minus the extention.
		object_name = split_text[len(split_text) - 1].replace(".xml", "")

		screenshot_name = data["screenshot_links"][value]
		if create_thumbnail(object_path, object_name, screenshots_path, screenshot_name, directory) == False:
			if create_thumbnail(object_path, object_name, install_path, screenshot_name, directory) == False:
				create_thumbnail(object_path, object_name, install_path, screenshot_name + "_converted.dds", directory)

def create_thumbnail(object_path, name, base_path, path, directory):
	global data
	global item_list

	if path == "Data/UI/spawner/thumbs/Hotspot/empty.png":
		return

	try:
		with open(base_path + path) as f:
			pass
		try:
			image = Image.open(base_path + path, mode="r")
			width, height = image.size   # Get dimensions

			left = (width - height)/2
			right = (width + height)/2
			# Crop the center of the image
			image = image.crop((left, 0, right, height))
			image_size = 256

			image = image.resize((image_size, image_size))
			image.save(directory + name + '.png', 'PNG')

			item_list[object_path] = ("Data/UI/spawner/thumbs/extra/" + name + '.png')
			return True
		except IOError:
			print("Could not open image " + base_path + path)
			return True
	except IOError:
		# print("Could not open image " + base_path + path)
		return False

read_thumbnail_json(screenshot_json_path)
write_json()
