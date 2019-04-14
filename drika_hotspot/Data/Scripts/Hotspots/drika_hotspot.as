#include "hotspots/drika_element.as"
#include "hotspots/drika_slow_motion.as"
#include "hotspots/drika_on_input.as"
#include "hotspots/drika_set_morph_target.as"
#include "hotspots/drika_set_bone_inflate.as"
#include "hotspots/drika_send_character_message.as"
#include "hotspots/drika_animation.as"
#include "hotspots/drika_set_object_param.as"
#include "hotspots/drika_create_object.as"
#include "hotspots/drika_check_character_state.as"
#include "hotspots/drika_create_particle.as"
#include "hotspots/drika_display_image.as"
#include "hotspots/drika_display_text.as"
#include "hotspots/drika_go_to_line.as"
#include "hotspots/drika_load_level.as"
#include "hotspots/drika_on_character_enter_exit.as"
#include "hotspots/drika_on_item_enter_exit.as"
#include "hotspots/drika_play_music.as"
#include "hotspots/drika_play_sound.as"
#include "hotspots/drika_send_level_message.as"
#include "hotspots/drika_set_camera_param.as"
#include "hotspots/drika_set_character_param.as"
#include "hotspots/drika_set_character.as"
#include "hotspots/drika_set_color.as"
#include "hotspots/drika_set_enabled.as"
#include "hotspots/drika_set_level_param.as"
#include "hotspots/drika_set_velocity.as"
#include "hotspots/drika_start_dialogue.as"
#include "hotspots/drika_transform_object.as"
#include "hotspots/drika_wait_level_message.as"
#include "hotspots/drika_wait.as"
#include "hotspots/drika_billboard.as"

bool show_editor = false;
bool has_closed = true;
bool editing = false;
bool show_name = false;
string display_name = "Drika Hotspot";
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
float image_scale;
vec4 image_tint;
string image_path;
bool show_image = false;
string text;
int font_size;
string font_path;
bool show_text = false;
float text_opacity = 1.0;
bool hotspot_enabled = true;

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
	show_name = (this_hotspot.GetName() != "");
	display_name = this_hotspot.GetName();
    level.ReceiveLevelEvents(hotspot.GetID());
	ConvertDisplayColors();
	SortFunctionsAlphabetical();
	//When the user duplicates a hotspot the editormode is active and the left alt is pressed.
	if(EditorModeActive() && GetInputDown(0, "lalt")){
		duplicating = true;
	}
	InterpData();
}

void SortFunctionsAlphabetical(){
	sorted_element_names = drika_element_names.getKeys();
	sorted_element_names.sortAsc();
}

void SetEnabled(bool val){
	hotspot_enabled = val;
}

void RegisterObject(int id, string reference){
	object_references[reference] = id;
}

bool HasReferences(){
	for(uint i = 0; i < drika_elements.size(); i++){
	    if(drika_elements[i].GetReference() != ""){
			return true;
		}
	}
	return false;
}

array<string> GetReferences(){
	array<string> reference_strings;
	Log(info, "Getting references " + drika_elements.size());
	for(uint i = 0; i < drika_elements.size(); i++){
	    if(drika_elements[i].GetReference() != ""){
			Log(info, i + " ref " + drika_elements[i].GetReference());
			reference_strings.insertLast(drika_elements[i].GetReference());
		}
	}
	return reference_strings;
}

bool AcceptConnectionsTo(Object @other){
	if(drika_elements.size() > 0){
		if(GetCurrentElement().placeholder_id == other.GetID()){
			return false;
		}else if(GetCurrentElement().identifier_type == id && GetCurrentElement().connection_types.find(other.GetType()) != -1){
			return true;
		}
	}
	return false;
}

bool ConnectTo(Object @other){
	if(!post_init_done){

	}else{
		if(drika_elements.size() > 0){
			bool return_value = GetCurrentElement().ConnectTo(other);
			Save();
			return return_value;
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
	for(uint i = 0; i < drika_elements.size(); i++){
		drika_elements[i].Delete();
	}
}

void SetParameters(){
	params.AddIntCheckbox("Debug Current Line", debug_current_line);
	debug_current_line = (params.GetInt("Debug Current Line") == 1);
}

void InterpData(){
	int line_index = 0;
	if(params.HasParam("Script Data")){
		JSON data;
		if(!data.parseString(params.GetString("Script Data"))){
			Log(warning, "Unable to parse the JSON in the Script Data!");
		}else{
			for( uint i = 0; i < data.getRoot()["functions"].size(); ++i ) {
				drika_elements.insertLast(InterpElement(data.getRoot()["functions"][i]));
				drika_indexes.insertLast(drika_elements.size() - 1);
				line_index += 1;
			}
		}
	}
	Log(info, "Interp of script done. Hotspot number: " + this_hotspot.GetID());
	ReorderElements();
}

DrikaElement@ InterpElement(JSONValue &in function_json){
	if(function_json["function_name"].asString() == "set_object_param"){
		return DrikaSetObjectParam(function_json);
	}else if(function_json["function_name"].asString() == "create_object"){
		return DrikaCreateObject(function_json);
	}else if(function_json["function_name"].asString() == "check_character_state"){
		return DrikaCheckCharacterState(function_json);
	}else if(function_json["function_name"].asString() == "create_particle"){
		return DrikaCreateParticle(function_json);
	}else if(function_json["function_name"].asString() == "display_image"){
		return DrikaDisplayImage(function_json);
	}else if(function_json["function_name"].asString() == "display_text"){
		return DrikaDisplayText(function_json);
	}else if(function_json["function_name"].asString() == "go_to_line"){
		return DrikaGoToLine(function_json);
	}else if(function_json["function_name"].asString() == "load_level"){
		return DrikaLoadLevel(function_json);
	}else if(function_json["function_name"].asString() == "on_character_enter_exit"){
		return DrikaOnCharacterEnterExit(function_json);
	}else if(function_json["function_name"].asString() == "on_item_enter_exit"){
		return DrikaOnItemEnterExit(function_json);
	}else if(function_json["function_name"].asString() == "play_music"){
		return DrikaPlayMusic(function_json);
	}else if(function_json["function_name"].asString() == "play_sound"){
		return DrikaPlaySound(function_json);
	}else if(function_json["function_name"].asString() == "send_level_message"){
		return DrikaSendLevelMessage(function_json);
	}else if(function_json["function_name"].asString() == "set_camera_param"){
		return DrikaSetCameraParam(function_json);
	}else if(function_json["function_name"].asString() == "set_character_param"){
		return DrikaSetCharacterParam(function_json);
	}else if(function_json["function_name"].asString() == "set_character"){
		return DrikaSetCharacter(function_json);
	}else if(function_json["function_name"].asString() == "set_color"){
		return DrikaSetColor(function_json);
	}else if(function_json["function_name"].asString() == "set_enabled"){
		return DrikaSetEnabled(function_json);
	}else if(function_json["function_name"].asString() == "set_level_param"){
		return DrikaSetLevelParam(function_json);
	}else if(function_json["function_name"].asString() == "set_velocity"){
		return DrikaSetVelocity(function_json);
	}else if(function_json["function_name"].asString() == "start_dialogue"){
		return DrikaStartDialogue(function_json);
	}else if(function_json["function_name"].asString() == "transform_object"){
		return DrikaTransformObject(function_json);
	}else if(function_json["function_name"].asString() == "wait_level_message"){
		return DrikaWaitLevelMessage(function_json);
	}else if(function_json["function_name"].asString() == "wait"){
		return DrikaWait(function_json);
	}else if(function_json["function_name"].asString() == "slow_motion"){
		return DrikaSlowMotion(function_json);
	}else if(function_json["function_name"].asString() == "on_input"){
		return DrikaOnInput(function_json);
	}else if(function_json["function_name"].asString() == "set_morph_target"){
		return DrikaSetMorphTarget(function_json);
	}else if(function_json["function_name"].asString() == "set_bone_inflate"){
		return DrikaSetBoneInflate(function_json);
	}else if(function_json["function_name"].asString() == "send_character_message"){
		return DrikaSendCharacterMessage(function_json);
	}else if(function_json["function_name"].asString() == "animation"){
		return DrikaAnimation(function_json);
	}else if(function_json["function_name"].asString() == "billboard"){
		return DrikaBillboard(function_json);
	}else{
		//Either an empty line or an unknown command is in the comic.
		Log(warning, "Unknown command found: " + function_json["function_name"].asString());
		return DrikaElement();
	}
}

void PostInit(){
	post_init_done = true;
	for(uint i = 0; i < drika_elements.size(); i++){
		drika_elements[i].PostInit();
	}
	duplicating = false;
}

void LaunchCustomGUI(){
	show_editor = !show_editor;
	if(show_editor){
		level.SendMessage("drika_hotspot_editing " + this_hotspot.GetID());
		has_closed = false;
		if(drika_elements.size() > 0){
			GetCurrentElement().StartEdit();
		}
	}
}

void Update(){
	if(!post_init_done){
		PostInit();
		return;
	}

	if(!show_editor && !has_closed){
		has_closed = true;
		Reset();
		Save();
	}

	if(EditorModeActive() && editing == false){
		SwitchToEditing();
	}else if(!EditorModeActive() && editing == true){
		SwitchToPlaying();
	}

	if(!script_finished && drika_indexes.size() > 0 && hotspot_enabled){
		if(!show_editor){
			if(messages.size() > 0){
				for(uint i = 0; i < messages.size(); i++){
					GetCurrentElement().ReceiveMessage(messages[i]);
				}
			}
			if(GetCurrentElement().Trigger()){
				if(current_line == int(drika_indexes.size() - 1)){
					script_finished = true;
				}else{
					current_line += 1;
					display_index = drika_indexes[current_line];
				}
			}
		}else{
			GetCurrentElement().Update();
		}
		messages.resize(0);
	}
}

void SwitchToEditing(){
	editing = true;
}

void SwitchToPlaying(){
	if(this_hotspot.IsSelected()){
		show_editor = false;
		this_hotspot.SetSelected(false);
	}
	editing = false;
	Reset();
}

void SelectedChanged(){
	is_selected = this_hotspot.IsSelected();
	if(is_selected){
		if(!show_editor && drika_elements.size() != 0){
			GetCurrentElement().StartEdit();
		}
		show_editor = true;
		level.SendMessage("drika_hotspot_editing " + this_hotspot.GetID());
	}
}

bool reorded = false;
int display_index = 0;
int drag_target_line = 0;
bool update_scroll = false;
bool debug_current_line = false;

void DrawEditor(){
	if(show_name){
		DebugDrawText(this_hotspot.GetTranslation() + vec3(0, 0.5, 0), display_name, 1.0, false, _delete_on_draw);
	}
	if(show_editor){
		DebugDrawBillboard("Data/Textures/drika_hotspot.png", this_hotspot.GetTranslation(), 0.5, vec4(0.25, 1.0, 0.25, 1.0), _delete_on_update);
	}else{
		DebugDrawBillboard("Data/Textures/drika_hotspot.png", this_hotspot.GetTranslation(), 0.5, vec4(0.5, 0.5, 0.5, 1.0), _delete_on_update);
	}
	if(show_editor){
		ImGui_PushStyleColor(ImGuiCol_WindowBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_PopupBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgActive, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgCollapsed, background_color);
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
		ImGui_Begin("Drika Hotspot " + (show_name?" - " + display_name:"" + this_hotspot.GetID()) + "###Drika Hotspot", show_editor, ImGuiWindowFlags_MenuBar);
		ImGui_PopStyleVar();

		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 150));
		ImGui_SetNextWindowSize(vec2(450.0f, 250.0f), ImGuiSetCond_FirstUseEver);
        if(ImGui_BeginPopupModal("Edit", ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse)){
			ImGui_BeginChild("Element Settings", vec2(-1, ImGui_GetWindowHeight() - 60));
			GetCurrentElement().DrawSettings();
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
				AddFunctionMenuItems();
				ImGui_EndMenu();
			}
			if(ImGui_BeginMenu("Settings")){
				if(ImGui_Checkbox("Show Name", show_name)){
					if(!show_name){
						this_hotspot.SetName("");
					}else{
						this_hotspot.SetName(display_name);
					}
				}
				if(show_name){
					if(ImGui_InputText("Name", display_name, 64)){
						this_hotspot.SetName(display_name);
					}
				}
				if(ImGui_Checkbox("Debug Current Line", debug_current_line)){
					params.SetInt("Debug Current Line", debug_current_line?1:0);
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
					Save();
				}
			}
			if(ImGui_ImageButton(duplicate_icon, vec2(10), vec2(0), vec2(1), 5, vec4(0))){
				if(drika_elements.size() > 0){
					duplicating = true;
					DrikaElement@ new_element = InterpElement(GetCurrentElement().GetSaveData());
					InsertElement(new_element);
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
						GetCurrentElement().StartSettings();
						ImGui_OpenPopup("Edit");
					}
				}else{
					GetCurrentElement().EditDone();
					display_index = int(item_no);
					current_line = int(i);
					GetCurrentElement().StartEdit();
				}

			}
			if(ImGui_IsItemHovered() && ImGui_IsMouseClicked(1)){
				GetCurrentElement().LeftClick();
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
		if(drika_elements.size() > 0){
			GetCurrentElement().DrawEditing();
		}
		ImGui_PopStyleColor(17);
	}
	if(reorded && !ImGui_IsMouseDragging(0)){
		reorded = false;
		ReorderElements();
		Save();
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
}

void InsertElement(DrikaElement@ new_element){
	if(drika_elements.size() > 0){
		GetCurrentElement().EditDone();
	}
	new_element.PostInit();
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
	if(post_init_done && drika_elements.size() > 0){
		GetCurrentElement().StartEdit();
		Save();
	}
}

void ReceiveMessage(string msg){
    TokenIterator token_iter;
    token_iter.Init();

    if(!token_iter.FindNextToken(msg) || drika_elements.size() == 0){
        return;
    }
    string token = token_iter.GetToken(msg);
	// Discard the messages when this hotspot is disabled.
	if(token == "level_event"){
		if(editing){
			if(show_editor){
				array<string> editor_messages;
				while(token_iter.FindNextToken(msg)){
					editor_messages.insertLast(token_iter.GetToken(msg));
				}
				//This message is send when ctrl + s is pressed.
				if(editor_messages[0] == "save_selected_dialogue"){
					Log(info, "SAVE!");
					Save();
				}
				GetCurrentElement().ReceiveEditorMessage(editor_messages);
			}
		}else{
			token_iter.FindNextToken(msg);
			string message = token_iter.GetToken(msg);
			if(message == "drika_hotspot_editing" && token_iter.FindNextToken(msg)){
				int id = atoi(token_iter.GetToken(msg));
				if(id != this_hotspot.GetID()){
					show_editor = false;
				}
			}
			if(!script_finished && drika_indexes.size() > 0 && hotspot_enabled){
				messages.insertLast(message);
			}
		}
	}
}

void HandleEvent(string event, MovementObject @mo){
	if(event == "enter" || event == "exit"){
		if(!script_finished && drika_indexes.size() > 0 && hotspot_enabled){
			GetCurrentElement().ReceiveMessage((event == "enter")?"CharacterEnter":"CharacterExit", mo.GetID());
			ScriptParams@ char_params = ReadObjectFromID(mo.GetID()).GetScriptParams();
			if(char_params.HasParam("Teams")) {
				string team = char_params.GetString("Teams");
				GetCurrentElement().ReceiveMessage((event == "enter")?"CharacterEnter":"CharacterExit", team, mo.GetID());
			}
		}
	}
}

void HandleEventItem(string event, ItemObject @obj){
	Log(info, "on item works!");
	if(event == "enter"){
		if(!script_finished && drika_indexes.size() > 0 && hotspot_enabled){
			GetCurrentElement().ReceiveMessage("ItemEnter", obj.GetID());
			GetCurrentElement().ReceiveMessage("ItemEnter", obj.GetLabel(), obj.GetID());
		}
	}
}

void Reset(){
	if(drika_elements.size() == 0){
		return;
	}
	GetCurrentElement().EditDone();
	//If the user is editing the script then stay with the current line to edit.
	current_line = 0;
	display_index = drika_indexes[current_line];
	object_references.deleteAll();

	script_finished = false;
	for(int i = int(drika_indexes.size() - 1); i > -1; i--){
		drika_elements[drika_indexes[i]].Reset();
	}
	if(editing && show_editor){
		GetCurrentElement().StartEdit();
	}
}

void Draw(){
	if(debug_current_line && drika_elements.size() > 0){
		if(!hotspot_enabled){
			DebugDrawText(this_hotspot.GetTranslation() + vec3(0, 0.75, 0), "Disabled", 1.0, false, _delete_on_draw);
		}else{
			DebugDrawText(this_hotspot.GetTranslation() + vec3(0, 0.75, 0), GetCurrentElement().GetDisplayString(), 1.0, false, _delete_on_draw);
		}
	}
	if(show_text){
		vec2 pos(GetScreenWidth() *0.5, GetScreenHeight() *0.2);
		TextMetrics metrics = GetTextAtlasMetrics(font_path, font_size, 0, text);
		pos.x -= metrics.bounds_x * 0.5;
		DrawTextAtlas(font_path, font_size, 0, text,
					  int(pos.x+2), int(pos.y+2), vec4(vec3(0.0f), text_opacity * 0.5));
		DrawTextAtlas(font_path, font_size, 0, text,
					  int(pos.x), int(pos.y), vec4(vec3(1.0f), text_opacity));
	}
	if(show_image){
		HUDImage@ image = hud.AddImage();
		image.SetImageFromPath(image_path);

		vec2 screen_dims = vec2(GetScreenWidth(), GetScreenHeight());
		float screen_aspect_ratio = screen_dims.x / screen_dims.y;

		vec2 image_dims = vec2(image.GetWidth(), image.GetHeight());
		float image_aspect_ratio = image_dims.x / image_dims.y;

		float fill_scale = screen_aspect_ratio <= image_aspect_ratio ?
			screen_dims.x / image_dims.x :
			screen_dims.y / image_dims.y;

		float new_image_scale = image_scale * fill_scale;
		vec2 image_pos = vec2(
			screen_dims.x - (image_dims.x * new_image_scale),
			screen_dims.y - (image_dims.y * new_image_scale)) * 0.5f;

		image.scale = vec3(new_image_scale, new_image_scale, 0.0f);
		image.position = vec3(image_pos.x, image_pos.y, 5.0f);
		image.color = image_tint;
	}
}

void ShowImage(string _image_path, vec4 _image_tint, float _image_scale){
	if(_image_path == ""){
		show_image = false;
	}else{
		image_scale = _image_scale;
		image_tint = _image_tint;
		image_path = _image_path;
		show_image = true;
	}
}

void ShowText(string _text, int _font_size, string _font_path){
	if(_text == ""){
		show_text = false;
	}else{
		text = _text;
		font_size = _font_size;
		font_path = _font_path;
		show_text = true;
	}
}

void Save(){
	JSON data;
	JSONValue functions;

	for(uint i = 0; i < drika_indexes.size(); i++){
		functions.append(drika_elements[drika_indexes[i]].GetSaveData());
	}
	data.getRoot()["functions"] = functions;
	params.SetString("Script Data", data.writeString(false));
}

int GetJSONInt(JSONValue data, string var_name, int default_value){
	if(data.isMember(var_name) && data[var_name].isInt()){
		return data[var_name].asInt();
	}else{
		return default_value;
	}
}

string GetJSONString(JSONValue data, string var_name, string default_value){
	if(data.isMember(var_name) && data[var_name].isString()){
		return data[var_name].asString();
	}else{
		return default_value;
	}
}

vec3 GetJSONVec3(JSONValue data, string var_name, vec3 default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		return vec3(data[var_name][0].asFloat(), data[var_name][1].asFloat(), data[var_name][2].asFloat());
	}else{
		return default_value;
	}
}

vec4 GetJSONVec4(JSONValue data, string var_name, vec4 default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		return vec4(data[var_name][0].asFloat(), data[var_name][1].asFloat(), data[var_name][2].asFloat(), data[var_name][3].asFloat());
	}else{
		return default_value;
	}
}

bool GetJSONBool(JSONValue data, string var_name, bool default_value){
	if(data.isMember(var_name) && data[var_name].isBool()){
		return data[var_name].asBool();
	}else{
		return default_value;
	}
}

float GetJSONFloat(JSONValue data, string var_name, float default_value){
	if(data.isMember(var_name) && data[var_name].isNumeric()){
		return data[var_name].asFloat();
	}else{
		return default_value;
	}
}

array<float> GetJSONFloatArray(JSONValue data, string var_name, array<float> default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		array<float> values;
		for(uint i = 0; i < data[var_name].size(); i++){
			values.insertLast(data[var_name][i].asFloat());
		}
		return values;
	}else{
		return default_value;
	}
}

array<int> GetJSONIntArray(JSONValue data, string var_name, array<int> default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		array<int> values;
		for(uint i = 0; i < data[var_name].size(); i++){
			values.insertLast(data[var_name][i].asInt());
		}
		return values;
	}else{
		return default_value;
	}
}

array<string> GetJSONStringArray(JSONValue data, string var_name, array<string> default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		array<string> values;
		for(uint i = 0; i < data[var_name].size(); i++){
			values.insertLast(data[var_name][i].asString());
		}
		return values;
	}else{
		return default_value;
	}
}

array<JSONValue> GetJSONValueArray(JSONValue data, string var_name, array<JSONValue> default_value){
	if(data.isMember(var_name) && data[var_name].isArray()){
		array<JSONValue> values;
		for(uint i = 0; i < data[var_name].size(); i++){
			values.insertLast(data[var_name][i]);
		}
		return values;
	}else{
		return default_value;
	}
}

void AddFunctionMenuItems(){
	for(uint i = 0; i < sorted_element_names.size(); i++){
		drika_element_types current_element_type = drika_element_types(drika_element_names[sorted_element_names[i]]);
		ImGui_PushStyleColor(ImGuiCol_Text, display_colors[current_element_type]);
		if(ImGui_MenuItem(sorted_element_names[i])){
			InsertElement(@CreateNewFunction(current_element_type));
		}
		ImGui_PopStyleColor();
	}
}

DrikaElement@ CreateNewFunction(drika_element_types element_type) {
	switch(element_type){
		case drika_wait_level_message:
			return DrikaWaitLevelMessage();
		case drika_wait:
			return DrikaWait();
		case drika_set_enabled:
			return DrikaSetEnabled();
		case drika_set_character:
			return DrikaSetCharacter();
		case drika_create_particle:
			return DrikaCreateParticle();
		case drika_play_sound:
			return DrikaPlaySound();
		case drika_go_to_line:
			return DrikaGoToLine();
		case drika_on_character_enter_exit:
			return DrikaOnCharacterEnterExit();
		case drika_on_item_enter_exit:
			return DrikaOnItemEnterExit();
		case drika_send_level_message:
			return DrikaSendLevelMessage();
		case drika_start_dialogue:
			return DrikaStartDialogue();
		case drika_set_object_param:
			return DrikaSetObjectParam();
		case drika_set_level_param:
			return DrikaSetLevelParam();
		case drika_set_camera_param:
			return DrikaSetCameraParam();
		case drika_create_object:
			return DrikaCreateObject();
		case drika_transform_object:
			return DrikaTransformObject();
		case drika_set_color:
			return DrikaSetColor();
		case drika_play_music:
			return DrikaPlayMusic();
		case drika_set_character_param:
			return DrikaSetCharacterParam();
		case drika_display_text:
			return DrikaDisplayText();
		case drika_display_image:
			return DrikaDisplayImage();
		case drika_load_level:
			return DrikaLoadLevel();
		case drika_check_character_state:
			return DrikaCheckCharacterState();
		case drika_set_velocity:
			return DrikaSetVelocity();
		case drika_slow_motion:
			return DrikaSlowMotion();
		case drika_on_input:
			return DrikaOnInput();
		case drika_set_morph_target:
			return DrikaSetMorphTarget();
		case drika_set_bone_inflate:
			return DrikaSetBoneInflate();
		case drika_send_character_message:
			return DrikaSendCharacterMessage();
		case drika_animation:
			return DrikaAnimation();
		case drika_billboard:
			return DrikaBillboard();
	}
	return DrikaElement();
}
