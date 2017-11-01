#! /usr/bin/python
import os
import xml.etree.ElementTree as etree
from lxml import etree

path = "/run/Hyperdisk/SteamLibraryLinux/steamapps/common/Overgrowth/Data/Animations"
index = 0

root = etree.Element('root')
for file in os.listdir(path):
    if file.endswith(".anm"):
        print(os.path.join("Data/Animations/", file))
        element = etree.SubElement(root, "path", key="animation" + str(index), path=os.path.join("Data/Animations/", file))
        index += 1

tree = etree.ElementTree(root)
tree.write("animation_browser_paths.xml", pretty_print=True, xml_declaration=True, encoding='utf-8', method="xml")
