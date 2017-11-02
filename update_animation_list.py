#! /usr/bin/python
import os
import json
import xml.etree.ElementTree as etree
from lxml import etree

main_path = "/run/Hyperdisk/SteamLibraryLinux/steamapps/common/Overgrowth/"
therium_path = "/run/Hyperdisk/SteamLibraryLinux/steamapps/workshop/content/25000/1126025778/"
index = 0
root_element = etree.Element('root')
data = {}

def write_json():
    global data
    find_animations_json("Data/Animations/", main_path)
    find_animations_json("Data/Custom/timbles/therium-2/Animations/", therium_path)
    print json.dumps(data, indent=4)
    with open('animation_browser_paths.json', 'w') as outfile:
        json.dump(data, outfile, indent = 4, ensure_ascii = False)

def find_animations_json (base, path):
    global index
    global data

    for root, dirs, files in os.walk(path):
        for name in files:
            if name.endswith((".anm")):
                relDir = os.path.relpath(root, path)
                relFile = os.path.join(relDir, name)
                print(relFile);
                data["animation" + str(index)] = name
                index += 1

def write_xml():
    find_animations_xml("Data/Animations/", main_path)
    find_animations_xml("Data/Custom/timbles/therium-2/Animations/", therium_path)
    tree = etree.ElementTree(root_element)
    tree.write("animation_browser_paths.xml", pretty_print=True, xml_declaration=True, encoding='utf-8', method="xml")

def find_animations_xml (base, path):
    global index
    global root_element

    for root, dirs, files in os.walk(path):
        for name in files:
            if name.endswith((".anm")):
                print(os.path.join(base, name))
                element = etree.SubElement(root_element, "path", key="animation" + str(index), path=os.path.join(base, name))
                index += 1

write_json()
