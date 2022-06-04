#! /usr/bin/python
from os import walk
from os import path
import json
import xml.etree.cElementTree as ET
from lxml import etree
from PIL import Image

root_element = etree.Element('root')

tileset_path = "./Data/Textures/ENEMIES/spritesheets/"
f = []

for (dirpath, dirnames, filenames) in walk(tileset_path):
	f.extend(filenames)
	break

for file_name in f:
	image = Image.open(tileset_path + file_name)
	name = path.splitext(file_name)[0]

	if image.size[1] == 32:
		print("convert image " + file_name)
		new_image = image.resize((int(image.size[0] / 2), int(image.size[1] / 2)), Image.NEAREST)
		new_image.save(fp=tileset_path + file_name, quality=100, optimize=True)

	xml_path = "./Data/Objects/" + name + ".xml"
	exists = path.exists(xml_path)
	if exists == False:
		texture_path = (tileset_path + file_name).replace("./", "")
		print(texture_path)

		# create XML
		root = etree.Element('Object')
		model = etree.Element('Model')
		model.text = 'Data/Models/horizontal_2d_plane.obj'

		colormap = etree.Element('ColorMap')
		colormap.text = texture_path

		normalmap = etree.Element('NormalMap')
		normalmap.text = 'Data/Textures/normal.tga'

		shadername = etree.Element('ShaderName')
		shadername.text = 'top_down_2d #TANGENT'

		flags = etree.Element('flags')
		flags.set('no_collision', 'false')

		root.append(model)
		root.append(colormap)
		root.append(normalmap)
		root.append(shadername)
		root.append(flags)

		et = etree.ElementTree(root)
		et.write(xml_path, pretty_print=True, xml_declaration=True)

objects_path = "./Data/Objects/"
objects = []

for (dirpath, dirnames, filenames) in walk(objects_path):
	objects.extend(filenames)
	break

object_list = { "Assets" : [] }

for object_name in sorted(objects):
	object_list["Assets"].append("Data/Objects/" + object_name)

# print( json.dumps(object_list, indent=4) )
objects_json = open("./Data/Scripts/top_down_2d_assets.json", "w")
objects_json.write(json.dumps(object_list, indent=4))
objects_json.close()
