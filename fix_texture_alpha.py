#! /usr/bin/python3.9
import os
import json
import xml.etree.ElementTree as etree
from lxml import etree
from PIL import Image, ImageDraw, ImageFilter
from os import walk

textures_path = "./kenney/Data/Textures/kenney/Modular_Buildings"

index = 0
root_element = etree.Element('root')
data = {}
item_list = {}
# plant_names = ["tree_large", "tree_shrub", "tree_small", "treePine_small", "treePine_large", "balconyLadder_bottom", "balconyLadder_top", "balcony_typeA"]
# plant_names = ["fenceStraight", "fenceCurved"]
plant_names = []

def fix_texture_alpha(path):
	resolved_path =  os.path.abspath(path)
	print(resolved_path)
	f = []
	for (dirpath, dirnames, filenames) in walk(resolved_path):
		f.extend(filenames)
		break

	for model_path in f:
		if model_path[-3:] == 'png':
			print(model_path)
			im_rgb = Image.open(resolved_path + "/" + model_path)
			im_rgba = im_rgb.copy()
			if any(plant_name in model_path for plant_name in plant_names):
				pixdata = im_rgba.load()
				width, height = im_rgba.size
				for y in range(height):
					for x in range(width):
						if pixdata[x, y] < (20, 20, 20, 255):
							pixdata[x, y] = (255, 255, 255, 0)
				im_rgba.save(resolved_path + "/" + model_path)
				continue
			# else:
			# 	continue
			im_rgba.putalpha(5)
			im_rgba.save(resolved_path + "/" + model_path)

fix_texture_alpha(textures_path)
