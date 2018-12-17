#include "hotspots/drika_element.as"
#include "hotspots/drika_wait.as"
#include "hotspots/drika_wait_level_message.as"
#include "hotspots/drika_set_enabled.as"
#include "hotspots/drika_set_character.as"
#include "hotspots/drika_create_particle.as"
#include "hotspots/drika_play_sound.as"
#include "hotspots/drika_go_to_line.as"
#include "hotspots/drika_on_character_enter_exit.as"
#include "hotspots/drika_on_item_enter.as"
#include "hotspots/drika_send_level_message.as"
#include "hotspots/drika_start_dialogue.as"
#include "hotspots/drika_set_object_param.as"
#include "hotspots/drika_set_level_param.as"
#include "hotspots/drika_set_camera_param.as"
#include "hotspots/drika_create_object.as"
#include "hotspots/drika_transform_object.as"
#include "hotspots/drika_set_color.as"
#include "hotspots/drika_play_music.as"
#include "hotspots/drika_set_character_param.as"

bool editor_open = false;
bool editing = false;
bool closed = true;
bool script_finished = false;
int current_line = 0;
array<DrikaElement@> drika_elements;
array<int> drika_indexes;
bool post_init_done = false;
Object@ this_hotspot = ReadObjectFromID(hotspot.GetID());
string param_delimiter = "|";
array<string> messages;
bool is_selected = false;
const int _ragdoll_state = 4;
dictionary object_references;
string default_preview_mesh = "Data/Objects/primitives/edged_cone.xml";
bool duplicating = false;

// Coloring options
vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);
vec4 background_color(0.25, 0.25, 0.25, 0.98);
vec4 titlebar_color(0.15, 0.15, 0.15, 0.98);
vec4 item_hovered(0.2, 0.2, 0.2, 0.98);
vec4 item_clicked(0.1, 0.1, 0.1, 0.98);
vec4 text_color(0.7, 0.7, 0.7, 1.0);

TextureAssetRef delete_icon = LoadTexture("Data/UI/ribbon/images/icons/color/Delete.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
TextureAssetRef duplicate_icon = LoadTexture("Data/UI/ribbon/images/icons/color/Copy.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

void Init() {
    level.ReceiveLevelEvents(hotspot.GetID());
	ConvertDisplayColors();
	//When the user duplicates a hotspot the editormode is active and the left alt is pressed.
	if(EditorModeActive() && GetInputDown(0, "lalt")){
		duplicating = true;
	}
	InterpData();
	duplicating = false;
}

string RegisterObject(int id, string reference){
	if(object_references.exists(reference)){
		Log(warning, "Object reference already exists! " + reference);
		int i = 0;
		while(object_references.exists(reference + i)){
			i += 1;
		}
		object_references[reference + i] = id;
		return (reference + i);
	}else{
		object_references[reference] = id;
		return reference;
	}
}

bool AcceptConnectionsTo(Object @other){
	if(drika_elements.size() > 0){
		if(GetCurrentElement().connection_types.find(other.GetType()) != -1){
			return true;
		}
	}
	return false;
}

bool ConnectTo(Object @other){
	Log(info, "Connect to " + other.GetID());
	if(!post_init_done){
		Log(info, "Nr of elements " + drika_elements.size());
		for(uint i = 0; i < drika_elements.size(); i++){
			if(drika_elements[i].InitConnect(other)){
				return true;
			}
		}
	}else{
		if(drika_elements.size() > 0){
			return GetCurrentElement().ConnectTo(other);
		}
	}
	return false;
}

bool Disconnect(Object @other){
	if(drika_elements.size() > 0){
		return GetCurrentElement().Disconnect(other);
	}
	return false;
}

void DeRegisterObject(string reference){
	object_references.delete(reference);
}

int GetRegisteredObjectID(string reference){
	if(object_references.exists(reference)){
		return int(object_references[reference]);
	}else{
		return -1;
	}
}

void ConvertDisplayColors(){
	for(uint i = 0; i < display_colors.size(); i++){
		display_colors[i].x /= 255;
		display_colors[i].y /= 255;
		display_colors[i].z /= 255;
	}
}

void Dispose() {
    level.StopReceivingLevelEvents(hotspot.GetID());
}

void SetParameters(){
}

void InterpData(){
	int line_index = 0;
	while(params.HasParam("" + line_index)){
		array<string> line_elements = params.GetString("" + line_index).split(param_delimiter);
		if(line_elements[0] == ""){
			continue;
		}
		drika_elements.insertLast(InterpElement(line_elements));
		drika_indexes.insertLast(drika_elements.size() - 1);
		line_index += 1;
	}
	Log(info, "Interp of script done. Hotspot number: " + this_hotspot.GetID());
	ReorderElements();
}

DrikaElement@ InterpElement(array<string> &in line_elements){
	if(line_elements[0] == "set_character"){
		return DrikaSetCharacter(line_elements[1], line_elements[2], line_elements[3]);
	}else if(line_elements[0] == "set_enabled"){
		return DrikaSetEnabled(line_elements[1], line_elements[2], line_elements[3]);
	}else if(line_elements[0] == "wait"){
		return DrikaWait(line_elements[1]);
	}else if(line_elements[0] == "wait_level_message"){
		return DrikaWaitLevelMessage(line_elements[1]);
	}else if(line_elements[0] == "create_particle"){
		return DrikaCreateParticle(line_elements[1], line_elements[2], line_elements[3], line_elements[4], line_elements[5], line_elements[6], line_elements[7], line_elements[8]);
	}else if(line_elements[0] == "play_sound"){
		return DrikaPlaySound(line_elements[1], line_elements[2]);
	}else if(line_elements[0] == "go_to_line"){
		return DrikaGoToLine(line_elements[1]);
	}else if(line_elements[0] == "on_character_enter_exit"){
		return DrikaOnCharacterEnterExit(line_elements[1], line_elements[2], line_elements[3]);
	}else if(line_elements[0] == "on_item_enter"){
		return DrikaOnItemEnter(line_elements[1], line_elements[2]);
	}else if(line_elements[0] == "send_level_message"){
		return DrikaSendLevelMessage(line_elements[1]);
	}else if(line_elements[0] == "start_dialogue"){
		return DrikaStartDialogue(line_elements[1]);
	}else if(line_elements[0] == "set_object_param"){
		return DrikaSetObjectParam(line_elements[1], line_elements[2], line_elements[3], line_elements[4], line_elements[5]);
	}else if(line_elements[0] == "set_level_param"){
		return DrikaSetLevelParam(line_elements[1], line_elements[2]);
	}else if(line_elements[0] == "set_camera_param"){
		return DrikaSetCameraParam(line_elements[1], line_elements[2]);
	}else if(line_elements[0] == "create_object"){
		return DrikaCreateObject(line_elements[1], line_elements[2], line_elements[3]);
	}else if(line_elements[0] == "transform_object"){
		return DrikaTransformObject(line_elements[1], line_elements[2], line_elements[3]);
	}else if(line_elements[0] == "set_color"){
		return DrikaSetColor(line_elements[1], line_elements[2], line_elements[3], line_elements[4], line_elements[5]);
	}else if(line_elements[0] == "play_music"){
		return DrikaPlayMusic(line_elements[1], line_elements[2]);
	}else if(line_elements[0] == "set_character_param"){
		return DrikaSetCharacterParam(line_elements[1], line_elements[2], line_elements[3]);
	}else{
		//Either an empty line or an unknown command is in the comic.
		Log(warning, "Unknown command found: " + line_elements[0]);
		return DrikaElement();
	}
}

void Update(){
	if(!post_init_done){
		post_init_done = true;
		for(uint i = 0; i < drika_elements.size(); i++){
			drika_elements[i].PostInit();
		}
		return;
	}

	if(!editor_open && !closed){
		closed = true;
		if(drika_elements.size() > 0){
			GetCurrentElement().EditDone();
		}
	}else if(editor_open){
		closed = false;
	}

	if(EditorModeActive() && editing == false){
		SwitchToEditing();
	}else if(!EditorModeActive() && editing == true){
		SwitchToPlaying();
	}

	if(!script_finished && drika_indexes.size() > 0 && !EditorModeActive()){
		if(messages.size() > 0){
			for(uint i = 0; i < messages.size(); i++){
				GetCurrentElement().ReceiveMessage(messages[i]);
			}
			messages.resize(0);
		}
		if(GetCurrentElement().Trigger()){
			if(current_line == int(drika_indexes.size() - 1)){
				script_finished = true;
			}else{
				current_line += 1;
			}
		}
	}
}

void SwitchToEditing(){
	editing = true;
}

void SwitchToPlaying(){
	editing = false;
	Reset();
}

void SelectedChanged(){
	is_selected = this_hotspot.IsSelected();
	if(is_selected){
		editor_open = true;
		if(drika_elements.size() != 0){
			GetCurrentElement().StartEdit();
		}
		level.SendMessage("drika_hotspot_editing " + this_hotspot.GetID());
	}
}

bool reorded = false;
int display_index = 0;
int drag_target_line = 0;
bool update_scroll = false;

void DrawEditor(){
	if(this_hotspot.IsSelected() != is_selected){
		SelectedChanged();
	}
	DebugDrawBillboard("Data/Textures/drika_hotspot.png", this_hotspot.GetTranslation(), 0.5, vec4(0.5, 0.5, 0.5, 1.0), _delete_on_update);
	if(editor_open){
		ImGui_PushStyleColor(ImGuiCol_WindowBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_PopupBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgActive, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBg, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_MenuBarBg, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_Text, text_color);
		ImGui_PushStyleColor(ImGuiCol_Header, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_HeaderHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_HeaderActive, item_clicked);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrab, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabActive, item_clicked);
		ImGui_PushStyleColor(ImGuiCol_CloseButton, background_color);
		ImGui_PushStyleColor(ImGuiCol_Button, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_ButtonHovered, item_hovered);
		ImGui_PushStyleColor(ImGuiCol_ButtonActive, item_clicked);
		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 300));

		ImGui_SetNextWindowSize(vec2(600.0f, 400.0f), ImGuiSetCond_FirstUseEver);
		ImGui_SetNextWindowPos(vec2(100.0f, 100.0f), ImGuiSetCond_FirstUseEver);
		ImGui_Begin("Drika Hotspot " + "###Drika Hotspot", editor_open, ImGuiWindowFlags_MenuBar);
		ImGui_PopStyleVar();

		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 150));
		ImGui_SetNextWindowSize(vec2(450.0f, 250.0f), ImGuiSetCond_FirstUseEver);
        if(ImGui_BeginPopupModal("Edit", ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse)){
			ImGui_BeginChild("Element Settings", vec2(-1, ImGui_GetWindowHeight() - 60));
			GetCurrentElement().AddSettings();
			ImGui_EndChild();
			ImGui_BeginChild("Modal Buttons", vec2(-1, 60));
			if(ImGui_Button("Close")){
				GetCurrentElement().ApplySettings();
				ImGui_CloseCurrentPopup();
				Save();
			}
			ImGui_EndChild();
			ImGui_EndPopup();
		}
		ImGui_PopStyleVar();

		if(ImGui_BeginMenuBar()){
			if(ImGui_BeginMenu("Add")){
				if(ImGui_MenuItem("Set Character")){
					DrikaSetCharacter new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Set Enabled")){
					DrikaSetEnabled new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Wait For Level Message")){
					DrikaWaitLevelMessage new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Wait")){
					DrikaWait new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Create Particle")){
					DrikaCreateParticle new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Play Sound")){
					DrikaPlaySound new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Go To Line")){
					DrikaGoToLine new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("On Character Enter Exit")){
					DrikaOnCharacterEnterExit new_param();
					InsertElement(@new_param);
				}
				/* if(ImGui_MenuItem("On Item Enter")){
					DrikaOnItemEnter new_param();
					InsertElement(@new_param);
				} */
				if(ImGui_MenuItem("Send Level Message")){
					DrikaSendLevelMessage new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Start Dialogue")){
					DrikaStartDialogue new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Set Object Parameter")){
					DrikaSetObjectParam new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Set Level Parameter")){
					DrikaSetLevelParam new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Set Camera Parameter")){
					DrikaSetCameraParam new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Create Object")){
					DrikaCreateObject new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Transform Object")){
					DrikaTransformObject new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Set Color")){
					DrikaSetColor new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Play Music")){
					DrikaPlayMusic new_param();
					InsertElement(@new_param);
				}
				if(ImGui_MenuItem("Set Character Parameter")){
					DrikaSetCharacterParam new_param();
					InsertElement(@new_param);
				}
				ImGui_EndMenu();
			}
			if(ImGui_ImageButton(delete_icon, vec2(10), vec2(0), vec2(1), 5, vec4(0))){
				if(drika_elements.size() > 0){
					GetCurrentElement().Delete();
					int current_index = drika_indexes[current_line];

					drika_elements[drika_indexes[current_line]];

					drika_elements.removeAt(current_index);
					drika_indexes.removeAt(current_line);

					for(uint i = 0; i < drika_indexes.size(); i++){
						if(drika_indexes[i] > current_index){
							drika_indexes[i] -= 1;
						}
					}
					// If the last element is deleted then the target needs to be the previous element.
					if(current_line > 0 && current_line == int(drika_elements.size())){
						display_index = drika_indexes[current_line - 1];
						current_line -= 1;
					}else if(drika_elements.size() > 0){
						display_index = drika_indexes[current_line];
					}
					ReorderElements();
					//Remove the last one since all the saved elements have been saved down one index.
					params.Remove("" + drika_elements.size());
				}
			}
			if(ImGui_ImageButton(duplicate_icon, vec2(10), vec2(0), vec2(1), 5, vec4(0))){
				if(drika_elements.size() > 0){
					duplicating = true;
					array<string> line_elements = GetCurrentElement().GetSaveString().split(param_delimiter);
					InsertElement(InterpElement(line_elements));
					ReorderElements();
					duplicating = false;
				}
			}
			ImGui_EndMenuBar();
		}

		if(!ImGui_IsPopupOpen("Edit")){
			if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_UpArrow))){
				if(current_line > 0){
					display_index = drika_indexes[current_line - 1];
					current_line -= 1;
					update_scroll = true;
				}
			}else if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_DownArrow))){
				if(current_line < int(drika_elements.size() - 1)){
					display_index = drika_indexes[current_line + 1];
					current_line += 1;
					update_scroll = true;
				}
			}
		}

		int line_counter = 0;
		for(uint i = 0; i < drika_indexes.size(); i++){
			int item_no = drika_indexes[i];
			string line_number = drika_elements[item_no].index + ".";
			int initial_length = max(1, (7 - line_number.length()));
			for(int j = 0; j < initial_length; j++){
				line_number += " ";
			}
			vec4 text_color = drika_elements[item_no].GetDisplayColor();
			ImGui_PushStyleColor(ImGuiCol_Text, text_color);
			if(ImGui_Selectable(line_number + drika_elements[item_no].GetDisplayString(), display_index == int(item_no), ImGuiSelectableFlags_AllowDoubleClick)){
				if(ImGui_IsMouseDoubleClicked(0)){
					if(drika_elements[drika_indexes[i]].has_settings){
						ImGui_OpenPopup("Edit");
					}
				}else{
					GetCurrentElement().EditDone();
					display_index = int(item_no);
					current_line = int(i);
					GetCurrentElement().StartEdit();
				}
			}
			if(update_scroll && display_index == int(item_no)){
				update_scroll = false;
				ImGui_SetScrollHere(0.5);
			}
			ImGui_PopStyleColor();
			if(ImGui_IsItemActive() && !ImGui_IsItemHovered()){
				float drag_dy = ImGui_GetMouseDragDelta(0).y;
				if(drag_dy < 0.0 && i > 0){
					// Swap
					drika_indexes[i] = drika_indexes[i-1];
            		drika_indexes[i-1] = item_no;
					drag_target_line = i-1;
					reorded = true;
					ImGui_ResetMouseDragDelta();
				}else if(drag_dy > 0.0 && i < drika_elements.size() - 1){
					drika_indexes[i] = drika_indexes[i+1];
            		drika_indexes[i+1] = item_no;
					drag_target_line = i+1;
					reorded = true;
					ImGui_ResetMouseDragDelta();
				}
			}
			line_counter += 1;
		}
		ImGui_End();
		ImGui_PopStyleColor(17);
		if(drika_elements.size() > 0){
			GetCurrentElement().DrawEditing();
		}
	}
	if(reorded && !ImGui_IsMouseDragging(0)){
		reorded = false;
		ReorderElements();
	}
}

DrikaElement@ GetCurrentElement(){
	return drika_elements[drika_indexes[current_line]];
}

void ReorderElements(){
	for(uint index = 0; index < drika_indexes.size(); index++){
		DrikaElement@ current_element = drika_elements[drika_indexes[index]];
		current_element.SetIndex(index);
	}
	Save();
}

void InsertElement(DrikaElement@ new_element){
	if(drika_elements.size() > 0){
		GetCurrentElement().EditDone();
	}
	drika_elements.insertLast(new_element);
	//There are no functions in the list yet.
	if(drika_indexes.size() < 1){
		drika_indexes.insertLast(drika_elements.size() - 1);
		display_index = drika_indexes[0];
	//Add a the new function to the next line and make that line the current one.
	}else{
		drika_indexes.insertAt(current_line + 1, drika_elements.size() - 1);
		display_index = drika_indexes[current_line + 1];
		current_line += 1;
	}
	ReorderElements();
	GetCurrentElement().StartEdit();
}

void ReceiveMessage(string msg){
    TokenIterator token_iter;
    token_iter.Init();

    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
	if(token == "level_event"){
		token_iter.FindNextToken(msg);
		string message = token_iter.GetToken(msg);
		if(!script_finished && drika_indexes.size() > 0){
			messages.insertLast(message);
		}
		if(message == "drika_hotspot_editing" && token_iter.FindNextToken(msg)){
			int id = atoi(token_iter.GetToken(msg));
			if(id != this_hotspot.GetID()){
				editor_open = false;
			}
		}
	}
}

void HandleEvent(string event, MovementObject @mo){
	if(event == "enter" || event == "exit"){
		if(!script_finished && drika_indexes.size() > 0){
			GetCurrentElement().ReceiveMessage((event == "enter")?"CharacterEnter":"CharacterExit", mo.GetID());
			ScriptParams@ char_params = ReadObjectFromID(mo.GetID()).GetScriptParams();
			if(char_params.HasParam("Teams")) {
				string team = char_params.GetString("Teams");
				GetCurrentElement().ReceiveMessage((event == "enter")?"CharacterEnter":"CharacterExit", team);
			}
		}
	}
}

void HandleEventItem(string event, ItemObject @obj){
	Log(info, "on item works!");
	if(event == "enter"){
		if(!script_finished && drika_indexes.size() > 0){
			GetCurrentElement().ReceiveMessage("ItemEnter", obj.GetID());
			GetCurrentElement().ReceiveMessage("ItemEnter", obj.GetLabel());
		}
	}
}

void Reset(){
	if(drika_elements.size() == 0){
		return;
	}
	GetCurrentElement().EditDone();
	//If the user is editing the script then stay with the current line to edit.
	if(!editing){
		current_line = 0;
	}
	script_finished = false;
	for(int i = int(drika_indexes.size() - 1); i > -1; i--){
		drika_elements[drika_indexes[i]].Reset();
	}
	GetCurrentElement().StartEdit();
}

void Save(){
	for(uint i = 0; i < drika_indexes.size(); i++){
		string data = drika_elements[drika_indexes[i]].GetSaveString();
		params.SetString("" + drika_elements[drika_indexes[i]].index, data);
	}
}
