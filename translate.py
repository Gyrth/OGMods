#!/usr/bin/env python3

import http.client, urllib.parse
import requests
import os
import json
from xml.etree import ElementTree as etree
from lxml import etree
import re
from xml.dom import minidom

level_path = "/run/Hyperdisk/SteamLibraryLinux/steamapps/common/Overgrowth/Data/Levels"
# Replace the subscriptionKey string value with your valid subscription key.
subscriptionKey = ''

host = 'api.microsofttranslator.com'
translation_path = '/V2/Http.svc/Translate'
available_languages_path = '/V2/Http.svc/GetLanguagesForTranslate'
language_names_path = '/V2/Http.svc/GetLanguageNames'

target = 'fr-fr'
source_language = "en"
text = 'Hello'
params = '?to=' + target + '&text=' + urllib.parse.quote (text)

def get_suggestions ():
    headers = {'Ocp-Apim-Subscription-Key': subscriptionKey}
    conn = http.client.HTTPSConnection(host)
    conn.request ("GET", path + params, None, headers)
    response = conn.getresponse ()
    print (response.read ().decode("utf-8"))

def get_friendly_names (lang_codes):
    #headers = {'Ocp-Apim-Subscription-Key': subscriptionKey}
    #conn = http.client.HTTPSConnection(host)
    #params = urllib.parse.urlencode({'?languageCodes' : "[[de]]", 'locale': 'en'})
    #params = '?locale=en&languageCodes=[de,nl]'
    #conn.request('POST', language_names_path + params, None, headers)
    #response = conn.getresponse ()
    token_service_url = 'https://api.microsofttranslator.com/v2/Http.svc/GetLanguageNames?locale=en'
    params = 'languageCodes=[nl]'
    request_headers = {'Ocp-Apim-Subscription-Key': subscriptionKey}
    response = requests.post(token_service_url, params=params, headers=request_headers)
    response.raise_for_status()
    print (response.content)
    #print (response.read ().decode("utf-8"))

def get_supported_languages ():
    all_languages = []

    headers = {'Ocp-Apim-Subscription-Key': subscriptionKey}
    conn = http.client.HTTPSConnection(host)
    params = urllib.parse.urlencode({})
    conn.request ("GET", available_languages_path, params, headers)
    response = conn.getresponse ()

    root = etree.fromstring(response.read())
    tree = etree.ElementTree(root)

    for language in root:
        print(language.text)
        all_languages.append(language.text)
    #tree.write("output.xml", pretty_print=True, xml_declaration=True, encoding='utf-8', method="xml")

def get_friendly_name(langauge_code):
    headers = {'Ocp-Apim-Subscription-Key': subscriptionKey}
    conn = http.client.HTTPSConnection(host)
    params = urllib.parse.urlencode({})
    conn.request ("POST", language_names_path, params, headers)
    response = conn.getresponse ()

    root = etree.fromstring(response.read())
    tree = etree.ElementTree(root)

    for language in root:
        print(language.text)
        all_languages.append(language.text)

def read_level_files(level_info):
    for info in level_info:
        try:
            with open(info[0]) as f:
                remove_dialogue(info[0], info[1], info[2], language)
        except IOError:
            pass

def remove_dialogue(full_level_path, relative_path, file, language):
    with open(full_level_path) as f:
        lines = f.readlines()
        lines.pop(0)
        lines.insert (0, "<?xml version=\"1.0\"?>")
        lines.insert (1, "<XMLHOLDER>\n")
        lines.append("</XMLHOLDER>\n")

        new_element = etree.fromstring(''.join(lines))
        level_has_dialogue = False

        dialogue_counter = 0
        for parameters in new_element.iter('parameters'):
            children = parameters.getchildren()
            parameter_has_dialogue = False

            dialogue_path = "translation/Data/Dialogue/" + relative_path
            new_file_path = "/" + file.replace(".xml", "") + "_dialogue_" + str(dialogue_counter) + ".txt"
            full_dialogue_path = dialogue_path  + new_file_path

            # Find a parameter with a Script tag first
            for param in children:
                if param.get("name") == "Script":
                    # This element has a dialogue inside!
                    level_has_dialogue = True
                    parameter_has_dialogue = True
                    text = param.get("val")

                    os.makedirs(dialogue_path, exist_ok=True)
                    # Write the dialogue text out to a txt file.
                    dialogue_file = open(full_dialogue_path, "w")
                    dialogue_file.write(text)
                    dialogue_file.close()
                    param.getparent().remove(param)
                    dialogue_counter += 1

            # Then if it has a script set the Dialogue text, since Dialogue can be added somewhere without Script text.
            if parameter_has_dialogue:

                for param in children:
                    if param.get("name") == "Dialogue":
                        param.set("val", "Data/Dialogue/" + relative_path + new_file_path)

        if level_has_dialogue:
            tree = etree.ElementTree(new_element)
            new_level_path = "translation/Data/Levels/" + relative_path
            os.makedirs(new_level_path, exist_ok=True)

            xml_as_string = etree.tostring(tree).decode('utf-8')
            xml_as_string = xml_as_string.replace("<XMLHOLDER>\n", "")
            xml_as_string = xml_as_string.replace("</XMLHOLDER>", "")

            level_file = open(new_level_path + "/" + file, "w")
            level_file.write("<?xml version=\"2.0\" ?>\n")
            level_file.write(xml_as_string)
            level_file.close()

            #tree.write(new_level_path + "/" + file, pretty_print=True, xml_declaration=True, encoding='utf-8', method="xml")

def get_translation(text, to_language):
    params = '?from=' + source_language + '&to=' + to_language + '&text=' + urllib.parse.quote (text)
    headers = {'Ocp-Apim-Subscription-Key': subscriptionKey}
    conn = http.client.HTTPSConnection(host)
    conn.request ("GET", translation_path + params, None, headers)
    response = conn.getresponse ()

    new_element = etree.fromstring(response.read())
    tree = etree.ElementTree(new_element)
    #print(text, new_element.text)

    return new_element.text

def find_level_xml (path, file_paths):
    for root, dirs, files in os.walk(path):
        for name in files:
            if name.endswith((".xml")):
                relDir = ""

                fullDir = os.path.realpath(path)
                if root != path:
                    relDir = os.path.relpath(root, path)
                    fullDir = os.path.join(fullDir, relDir)
                fullDir = os.path.join(fullDir, name)

                #print(relDir)
                #print(fullDir)

                file_info = [fullDir, relDir, name]
                file_paths.append(file_info)

def find_dialogue_txt (path, file_paths):
    for root, dirs, files in os.walk(path):
        for name in files:
            if name.endswith((".txt")):
                relDir = ""

                fullDir = os.path.realpath(path)
                if root != path:
                    relDir = os.path.relpath(root, path)
                    fullDir = os.path.join(fullDir, relDir)
                fullDir = os.path.join(fullDir, name)

                #print(relDir)
                #print(fullDir)

                file_info = [fullDir, relDir, name]
                file_paths.append(file_info)

def translate_txt(full_level_path, relative_path, file, language):
    #print(full_level_path)
    with open(full_level_path) as f:
        lines = f.readlines()

        for line_index in range(len(lines)):
            line = lines[line_index]
            # Check if line begins with say.
            if line[:3] == "say":
                # Get the text
                #print(line)
                split_dialogue = line.split("\"")
                if len(split_dialogue) < 2:
                    continue
                dialogue = split_dialogue[3]
                # Remove the [wait 0.2] and split the text.
                split_dialogue = dialogue.split("[")
                dialogue = []
                for dia in split_dialogue:
                    second_split_dialogue = dia.split("]")
                    if len(second_split_dialogue) > 1:
                        dialogue.append(second_split_dialogue[1])
                    else:
                        # No [ or ] found in this line
                        dialogue.append(dia)
                for orig_text in dialogue:
                    translation = get_translation(orig_text, language)
                    if not translation is None:
                        print( orig_text + " --------- " + translation)
                        line = line.replace(orig_text, translation)
                lines[line_index] = line

        dialogue_path = "translation/Data/Translations/" + language
        os.makedirs(dialogue_path + "/" + relative_path, exist_ok=True)

        new_file_path = "/" + relative_path + "/" + file
        full_dialogue_path = dialogue_path  + new_file_path
        #print(full_dialogue_path)

        translated_dialogue_file = open(full_dialogue_path,"w")
        for line in lines:
            translated_dialogue_file.write(line)
        translated_dialogue_file.close()

#level_info = []
#find_level_xml(level_path, level_info)
#read_level_files(level_info)

dialogue_info = []
find_dialogue_txt("translation/Data/Dialogue/", dialogue_info)
for info in dialogue_info:
    translate_txt(info[0], info[1], info[2], "de")

#get_translation("hello", "en", "pt")

#get_supported_languages()
#get_friendly_names("ko")
