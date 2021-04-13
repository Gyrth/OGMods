#! /usr/bin/python3.9
from PIL import Image, ImageChops
from os import walk

def trim(im):
	bg = Image.new(im.mode, im.size, im.getpixel((0,0)))
	diff = ImageChops.difference(im, bg)
	# diff = ImageChops.add(diff, diff, 1.0, -100)
	bbox = diff.getbbox()
	print(bbox)
	if bbox is None:
		return im
	y = list(bbox)
	margin = 5
	y[0] -= margin
	y[1] -= margin
	y[2] += margin
	y[3] += margin

	bbox = tuple(y)
	if bbox:
		return im.crop(bbox)

def make_square(im, fill_color=(0, 0, 0, 0)):
	x, y = im.size
	size = max(x, y)
	new_im = Image.new('RGBA', (size, size), fill_color)
	new_im.paste(im, (int((size - x) / 2), int((size - y) / 2)))
	return new_im

# im = Image.open("test.png")
# im = trim(im)
# im = make_square(im)
# im.show()

for dirpath, dnames, fnames in walk("./"):
	for f in fnames:
		if f.endswith(".png"):
			image_path = dirpath + "/" + f
			print(image_path)
			im = Image.open(image_path)
			im = trim(im)
			im = make_square(im)
			im.save(image_path, "PNG")
