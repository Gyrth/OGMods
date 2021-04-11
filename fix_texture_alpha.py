#! /usr/bin/python3.9
import os
import json
import xml.etree.ElementTree as etree
from lxml import etree
from PIL import Image, ImageDraw, ImageFilter
from os import walk

textures_path = "./kenney/Data/Textures/kenney"

index = 0
root_element = etree.Element('root')
data = {}
item_list = {}

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
			im_rgba.putalpha(5)
			im_rgba.save(resolved_path + "/" + model_path)

fix_texture_alpha(textures_path)
