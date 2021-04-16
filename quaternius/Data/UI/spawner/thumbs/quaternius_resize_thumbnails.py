#! /usr/bin/python3.9
from PIL import Image, ImageChops
from os import walk

for dirpath, dnames, fnames in walk("./"):
	for f in fnames:
		if f.endswith(".png"):
			image_path = dirpath + "/" + f
			print(image_path)
			im = Image.open(image_path)
			im = im.resize((128, 128))
			# im.save(image_path, "PNG")
			im.save(image_path, optimize=True, quality=10)
