#! /usr/bin/python
import os
import xml.etree.ElementTree as etree
from lxml import etree

main_path = "/run/Hyperdisk/SteamLibraryLinux/steamapps/common/Overgrowth/Data/Animations"
therium_path = "/run/Hyperdisk/SteamLibraryLinux/steamapps/workshop/content/25000/1126025778/Data/Custom/timbles/therium-2/Animations"
index = 0
root_element = etree.Element('root')

def find_animations (path):
    global index
    global root_element

    for root, dirs, files in os.walk(path):
        for name in files:
            if name.endswith((".anm")):
                print(os.path.join("Data/Animations/", name))
                element = etree.SubElement(root_element, "path", key="animation" + str(index), path=os.path.join("Data/Animations/", name))
                index += 1

find_animations(main_path)
find_animations(therium_path)

tree = etree.ElementTree(root_element)
tree.write("animation_browser_paths.xml", pretty_print=True, xml_declaration=True, encoding='utf-8', method="xml")
