#! /usr/bin/python3.9
import os
import json
import xml.etree.ElementTree as etree
from lxml import etree
from PIL import Image, ImageDraw, ImageFilter
from os import walk

textures_path = "./"

index = 0
root_element = etree.Element('root')
data = {}
item_list = {}
plant_names = []

def fix_texture_alpha(path):
	resolved_path =  os.path.abspath(path)
	print(resolved_path)

	image_file_paths = []

	for dirpath, dnames, fnames in os.walk(resolved_path):
		for f in fnames:
			if f.endswith(".png"):
				image_file_path = os.path.join(dirpath, f)
				print(image_file_path);
				image_file_paths.append(image_file_path)

	for image_file_path in image_file_paths:
		im_rgb = Image.open(image_file_path)

		img2 = im_rgb.resize((1, 1))
		r, g, b, a = img2.getpixel((0, 0))
		if a == 5:
			continue

		im_rgba = im_rgb.copy()
		if any(plant_name in image_file_path for plant_name in plant_names):
			pixdata = im_rgba.load()
			width, height = im_rgba.size
			for y in range(height):
				for x in range(width):
					if pixdata[x, y] < (20, 20, 20, 255):
						pixdata[x, y] = (255, 255, 255, 0)
			im_rgba.save(image_file_path)
			continue
		im_rgba.putalpha(5)
		im_rgba.save(image_file_path)

fix_texture_alpha(textures_path)
