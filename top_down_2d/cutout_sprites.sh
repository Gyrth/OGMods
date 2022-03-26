#! /usr/bin/python
from os import walk
from os import path
import json
import xml.etree.cElementTree as ET
from lxml import etree
from PIL import Image

root_element = etree.Element('root')

image_path = "./Data/Textures/PixelPackTOPDOWN8BIT.png"

image = Image.open(image_path)
name = path.splitext(image_path)[0]
counter = 0

width, height = image.size

for y in range(int(height / 16)):
	for x in range(int(width / 16)):

		left = x * 16
		top = y * 16
		right = left + 16
		bottom = top + 16

		print(left, top, right, bottom)
		cropped_image = image.crop((left, top, right, bottom))
		resized_image = cropped_image.resize((32, 32), Image.NEAREST)

		print("convert image " + name)
		resized_image.save(fp="./out/" + str(counter) + ".png", quality=100, optimize=True)
		counter += 1
