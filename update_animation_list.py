#! /usr/bin/python
import os
import json
import xml.etree.ElementTree as etree
from lxml import etree

main_path = "/run/Hyperdisk/SteamLibraryLinux/steamapps/common/Overgrowth/"
custom_animations_path = "/run/Hyperdisk/SteamLibraryLinux/steamapps/workshop/content/25000/"

index = 0
root_element = etree.Element('root')
data = {}

def write_json():
    global data

    find_animations_json(main_path)
    get_custom_animations_json(custom_animations_path)

    print("Total animations found " + str(index));
    # print json.dumps(data, indent=4)
    with open('animation_browser/Data/Scripts/animation_browser_paths.json', 'w') as outfile:
        json.dump(data, outfile, indent = 4, ensure_ascii = False)

def get_custom_animations_json(path):
    for folder in os.listdir(path):
        find_animations_json(path + folder)

def get_custom_animations_xml(path):
    for folder in os.listdir(path):
        find_animations_xml(path + folder)

def find_animations_json (path):
    global index
    global data
    counter = 0
    mod_name = ""

    for root, dirs, files in os.walk(path):
        for name in files:
            if name.endswith((".anm")):
                relDir = os.path.relpath(root, path)
                relFile = os.path.join(relDir, name)
                # print(relFile);
                data["animation" + str(index)] = relFile
                counter += 1
                index += 1
    try:
        parser = etree.XMLParser(encoding='utf-8', recover=True)
        tree = etree.parse(path + "/mod.xml")
        root = tree.getroot()
        if root is not None:
            mod_name = root.find('Name').text
    except IOError:
        pass
    except etree.ParseError:
        pass
    if counter != 0 :
        print(str(counter) + " animations found in " + path + " " + mod_name);

def write_xml():
    find_animations_xml(main_path)
    get_custom_animations_xml(custom_animations_path)
    tree = etree.ElementTree(root_element)
    tree.write("animation_browser_paths.xml", pretty_print=True, xml_declaration=True, encoding='utf-8', method="xml")

def find_animations_xml (path):
    global index
    global root_element
    counter = 0

    for root, dirs, files in os.walk(path):
        for name in files:
            if name.endswith((".anm")):
                relDir = os.path.relpath(root, path)
                relFile = os.path.join(relDir, name)
                # print(relFile);
                element = etree.SubElement(root_element, "path", key="animation" + str(index), path=relFile)
                counter += 1
                index += 1
    print(str(counter) + " animations found in " + path);

write_json()
