#include "animation_group.as"
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
#include "hotspots/drika_character_control.as"
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
#include "hotspots/drika_read_write_savefile.as"
#include "hotspots/drika_dialogue.as"
#include "hotspots/drika_comment.as"
#include "hotspots/drika_ai_control.as"

bool show_editor = false;
bool has_closed = true;
bool editing = false;
bool show_name = false;
string display_name = "Drika Hotspot";
bool script_finished = false;
int current_line = 0;
array<DrikaElement@> drika_elements;
array<DrikaElement@> parallel_elements;
array<int> drika_indexes;
bool post_init_done = false;
Object@ this_hotspot = ReadObjectFromID(hotspot.GetID());
string param_delimiter = "|";
array<string> messages;
bool is_selected = false;
const int _ragdoll_state = 4;
array<ObjectReference@> object_references;
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
array<int> dialogue_actor_ids;
bool wait_for_fade = false;
bool in_dialogue_mode = false;

array<AnimationGroup@> all_animations;
array<AnimationGroup@> current_animations;
array<string> active_mods;

// Coloring options
vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);
vec4 background_color(0.25, 0.25, 0.25, 0.98);
vec4 titlebar_color(0.15, 0.15, 0.15, 0.98);
vec4 item_hovered(0.2, 0.2, 0.2, 0.98);
vec4 item_clicked(0.1, 0.1, 0.1, 0.98);
vec4 text_color(0.7, 0.7, 0.7, 1.0);

TextureAssetRef delete_icon = LoadTexture("Data/UI/ribbon/images/icons/color/Delete.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
TextureAssetRef duplicate_icon = LoadTexture("Data/UI/ribbon/images/icons/color/Copy.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

class ObjectReference{
	int id;
	string reference;
	ObjectReference(int _id, string _reference){
		id = _id;
		reference = _reference;
	}
}

void Init() {
	show_name = (this_hotspot.GetName() != "");
	display_name = this_hotspot.GetName();
    level.ReceiveLevelEvents(hotspot.GetID());
	ConvertDisplayColors();
	SortFunctionsAlphabetical();
	//When the user duplicates a hotspot the editormode is active and the left alt is pressed.
	if(EditorModeActive() && GetInputDown(0, "lalt")){
		duplicating = true;
	}else if(EditorModeActive() && GetInputDown(0, "lctrl") && GetInputDown(0, "v")){
		duplicating = true;
	}
	InterpData();
}

void QueryAnimation(string query){
	current_animations.resize(0);
	for(uint i = 0; i < all_animations.size(); i++){
		AnimationGroup@ current_group = all_animations[i];
		AnimationGroup new_group(current_group.name);
		for(uint j = 0; j < current_group.animations.size(); j++){
			if(ToLowerCase(current_group.animations[j]).findFirst(ToLowerCase(query)) != -1){
				new_group.AddAnimation(current_group.animations[j]);
			}
		}
		if(new_group.animations.size() > 0){
			current_animations.insertLast(@new_group);
		}
	}
}

string ToLowerCase(string input){
	string output;
	for(uint i = 0; i < input.length(); i++){
		if(input[i] >= 65 &&  input[i] <= 90){
			string lower_case('0');
			lower_case[0] = input[i] + 32;
			output += lower_case;
		}else{
			string new_character('0');
			new_character[0] = input[i];
			output += new_character;
		}
	}
	return output;
}

void SortFunctionsAlphabetical(){
	//Remove empty function names.
	for(uint i = 0; i < drika_element_names.size(); i++){
		if(drika_element_names[i] == ""){
			drika_element_names.removeAt(i);
			i--;
		}
	}
	sorted_element_names = drika_element_names;
	sorted_element_names.sortAsc();
}

void SetEnabled(bool val){
	hotspot_enabled = val;
}

void RegisterObject(int id, string reference){
	if(reference == ""){
		return;
	}
	bool already_registered = false;
	for(uint i = 0; i < object_references.size(); i++){
		//Already have this reference, so just change the id.
		if(object_references[i].reference == reference){
			object_references[i].id = id;
			already_registered = true;
		}
	}
	if(!already_registered){
		object_references.insertLast(ObjectReference(id, reference));
	}
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
	if(post_init_done){
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
	for(uint i = 0; i < object_references.size(); i++){
		if(object_references[i].reference == reference){
			return object_references[i].id;
		}
	}
	return -1;
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
	if(GetInputDown(0, "delete")){
		for(uint i = 0; i < drika_elements.size(); i++){
			drika_elements[i].Delete();
		}
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
				drika_elements.insertLast(InterpElement(none, data.getRoot()["functions"][i]));
				drika_indexes.insertLast(drika_elements.size() - 1);
				line_index += 1;
			}
		}
	}
	Log(info, "Interp of script done. Hotspot number: " + this_hotspot.GetID());
	ReorderElements();
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

	if(drika_indexes.size() > 0 && hotspot_enabled && !wait_for_fade){
		if(!show_editor){
			DeliverMessages();
			UpdateParallelOperations();

			if(!script_finished){
				if(GetCurrentElement().parallel_operation || GetCurrentElement().Trigger()){
					if(current_line == int(drika_indexes.size() - 1)){
						script_finished = true;
					}else{
						current_line += 1;
						display_index = drika_indexes[current_line];
					}
				}
			}
		}else{
			GetCurrentElement().Update();
		}
		messages.resize(0);
	}
}

void UpdateParallelOperations(){
	for(uint i = 0; i < parallel_elements.size(); i++){
		if(parallel_elements[i].Trigger()){
			parallel_elements.removeAt(i);
			i--;
		}
	}
	if(!script_finished){
		if(GetCurrentElement().parallel_operation){
			//Check if the element is already added.
			for(uint i = 0; i < parallel_elements.size(); i++){
				if(parallel_elements[i].index == GetCurrentElement().index){
					return;
				}
			}
			parallel_elements.insertLast(GetCurrentElement());
		}
	}
}

void DeliverMessages(){
	if(messages.size() > 0){
		for(uint i = 0; i < messages.size(); i++){
			GetCurrentElement().ReceiveMessage(messages[i]);
		}
	}
}

void SwitchToEditing(){
	editing = true;
}

void SwitchToPlaying(){
	if(this_hotspot.IsSelected()){
		this_hotspot.SetSelected(false);
	}
	show_editor = false;
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
	if(camera.GetFlags() == kPreviewCamera){
		return;
	}
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
		ImGui_SetNextWindowSize(vec2(700.0f, 450.0f), ImGuiSetCond_FirstUseEver);
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
			if(ImGui_IsItemHovered()){
				ImGui_PushStyleColor(ImGuiCol_PopupBg, titlebar_color);
				ImGui_SetTooltip("Delete");
				ImGui_PopStyleColor();
			}
			if(ImGui_ImageButton(duplicate_icon, vec2(10), vec2(0), vec2(1), 5, vec4(0))){
				if(drika_elements.size() > 0){
					duplicating = true;
					DrikaElement@ new_element = InterpElement(GetCurrentElement().drika_element_type, GetCurrentElement().GetSaveData());
					InsertElement(new_element);
					duplicating = false;
				}
			}
			if(ImGui_IsItemHovered()){
				ImGui_PushStyleColor(ImGuiCol_PopupBg, titlebar_color);
				ImGui_SetTooltip("Duplicate");
				ImGui_PopStyleColor();
			}
			ImGui_EndMenuBar();
		}

		if(!ImGui_IsPopupOpen("Edit")){
			if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_UpArrow))){
				if(current_line > 0){
					GetCurrentElement().EditDone();
					display_index = drika_indexes[current_line - 1];
					current_line -= 1;
					update_scroll = true;
					GetCurrentElement().StartEdit();
				}
			}else if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_DownArrow))){
				if(current_line < int(drika_elements.size() - 1)){
					GetCurrentElement().EditDone();
					display_index = drika_indexes[current_line + 1];
					current_line += 1;
					update_scroll = true;
					GetCurrentElement().StartEdit();
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
		ImGui_PopStyleColor(18);
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
			array<string> editor_messages;
			while(token_iter.FindNextToken(msg)){
				editor_messages.insertLast(token_iter.GetToken(msg));
			}
			//This message is send when ctrl + s is pressed.
			if(editor_messages[0] == "save_selected_dialogue"){
				Save();
			}else if(editor_messages[0] == "drika_hotspot_editing" && atoi(editor_messages[1]) != this_hotspot.GetID()){
				show_editor = false;
			}
			GetCurrentElement().ReceiveEditorMessage(editor_messages);
		}else{
			token_iter.FindNextToken(msg);
			string message = token_iter.GetToken(msg);

			if(!script_finished && drika_indexes.size() > 0 && hotspot_enabled){
				messages.insertLast(message);
			}
		}
	}else if(token == "drika_dialogue_add_animation_group"){
		token_iter.FindNextToken(msg);
		string group_name = token_iter.GetToken(msg);

		AnimationGroup new_group(group_name);
		all_animations.insertLast(@new_group);
	}else if(token == "drika_dialogue_add_animation"){
		token_iter.FindNextToken(msg);
		string new_animation = token_iter.GetToken(msg);

		all_animations[all_animations.size() -1].AddAnimation(new_animation);
	}else if(token == "drika_dialogue_fade_out_done"){
		in_dialogue_mode = !in_dialogue_mode;

		ClearDialogueActors();
		wait_for_fade = false;
	}else if(token == "drika_read_file"){
		token_iter.FindNextToken(msg);
		string file_content = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		string param_1 = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		int param_2 = atoi(token_iter.GetToken(msg));

		GetCurrentElement().ReceiveMessage(file_content, param_1, param_2);
	}else if(token == "drika_external_hotspot"){
		token_iter.FindNextToken(msg);
		string event = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		int char_id = atoi(token_iter.GetToken(msg));

		token_iter.FindNextToken(msg);
		int source_hotspot_id = atoi(token_iter.GetToken(msg));

		GetCurrentElement().ReceiveMessage(event, char_id, source_hotspot_id);
	}else if(token == "drika_ui_event"){

		token_iter.FindNextToken(msg);
		string event = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		int param_1 = atoi(token_iter.GetToken(msg));

		GetCurrentElement().ReceiveMessage(event, param_1);
	}
}

void HandleEvent(string event, MovementObject @mo){
	if(event == "enter" || event == "exit"){
		if(!script_finished && drika_indexes.size() > 0 && hotspot_enabled){
			GetCurrentElement().ReceiveMessage(event, mo.GetID());
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
	object_references.resize(0);
	parallel_elements.resize(0);

	script_finished = false;
	wait_for_fade = false;
	in_dialogue_mode = false;
	for(int i = int(drika_indexes.size() - 1); i > -1; i--){
		drika_elements[drika_indexes[i]].Reset();
	}
	if(editing && show_editor){
		GetCurrentElement().StartEdit();
	}
	ClearDialogueActors();
}

void AddDialogueActor(int character_id){
	MovementObject@ char = ReadCharacterID(character_id);
	if(dialogue_actor_ids.find(character_id) == -1){
		dialogue_actor_ids.insertLast(character_id);
		char.ReceiveScriptMessage("set_dialogue_control true");
		/* char.rigged_object().anim_client().Reset(); */
	}
}

void RemoveDialogueActor(int character_id){
	int index = dialogue_actor_ids.find(character_id);
	if(index != -1){
		MovementObject@ char = ReadCharacterID(dialogue_actor_ids[index]);
		char.ReceiveScriptMessage("set_dialogue_control false");
		/* char.rigged_object().anim_client().Reset(); */
		dialogue_actor_ids.removeAt(index);
	}
}

void ClearDialogueActors(){
	for(uint i = 0; i < dialogue_actor_ids.size(); i++){
		MovementObject@ char = ReadCharacterID(dialogue_actor_ids[i]);
		char.Execute("roll_ik_fade = 0.0f;");
		char.ReceiveScriptMessage("set_dialogue_control false");
		/* char.rigged_object().anim_client().Reset(); */
	}
	dialogue_actor_ids.resize(0);
}

void Draw(){
	if(camera.GetFlags() == kPreviewCamera){
		return;
	}
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
		JSONValue function_data = drika_elements[drika_indexes[i]].GetSaveData();
		function_data["function"] = JSONValue(drika_elements[drika_indexes[i]].drika_element_type);
		functions.append(function_data);
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
		drika_element_types current_element_type = drika_element_types(drika_element_names.find(sorted_element_names[i]));
		if(current_element_type == none){
			continue;
		}
		ImGui_PushStyleColor(ImGuiCol_Text, display_colors[current_element_type]);
		if(ImGui_MenuItem(sorted_element_names[i])){
			InsertElement(@InterpElement(current_element_type, JSONValue()));
		}
		ImGui_PopStyleColor();
	}
}

DrikaElement@ InterpElement(drika_element_types element_type, JSONValue &in function_json){
	drika_element_types target_element_type;
	if(element_type == none){
		if(function_json.isMember("function")){
			target_element_type = drika_element_types(function_json["function"].asInt());
		}else{
			Log(warning, "Found a function without a function identifier.");
		}
	}else{
		target_element_type = element_type;
	}

	switch(target_element_type){
		case drika_wait_level_message:
			return DrikaWaitLevelMessage(function_json);
		case drika_wait:
			return DrikaWait(function_json);
		case drika_set_enabled:
			return DrikaSetEnabled(function_json);
		case drika_set_character:
			return DrikaSetCharacter(function_json);
		case drika_create_particle:
			return DrikaCreateParticle(function_json);
		case drika_play_sound:
			return DrikaPlaySound(function_json);
		case drika_go_to_line:
			return DrikaGoToLine(function_json);
		case drika_on_character_enter_exit:
			return DrikaOnCharacterEnterExit(function_json);
		case drika_on_item_enter_exit:
			return DrikaOnItemEnterExit(function_json);
		case drika_send_level_message:
			return DrikaSendLevelMessage(function_json);
		case drika_start_dialogue:
			return DrikaStartDialogue(function_json);
		case drika_set_object_param:
			return DrikaSetObjectParam(function_json);
		case drika_set_level_param:
			return DrikaSetLevelParam(function_json);
		case drika_set_camera_param:
			return DrikaSetCameraParam(function_json);
		case drika_create_object:
			return DrikaCreateObject(function_json);
		case drika_transform_object:
			return DrikaTransformObject(function_json);
		case drika_set_color:
			return DrikaSetColor(function_json);
		case drika_play_music:
			return DrikaPlayMusic(function_json);
		case drika_character_control:
			return DrikaCharacterControl(function_json);
		case drika_display_text:
			return DrikaDisplayText(function_json);
		case drika_display_image:
			return DrikaDisplayImage(function_json);
		case drika_load_level:
			return DrikaLoadLevel(function_json);
		case drika_check_character_state:
			return DrikaCheckCharacterState(function_json);
		case drika_set_velocity:
			return DrikaSetVelocity(function_json);
		case drika_slow_motion:
			return DrikaSlowMotion(function_json);
		case drika_on_input:
			return DrikaOnInput(function_json);
		case drika_set_morph_target:
			return DrikaSetMorphTarget(function_json);
		case drika_set_bone_inflate:
			return DrikaSetBoneInflate(function_json);
		case drika_send_character_message:
			return DrikaSendCharacterMessage(function_json);
		case drika_animation:
			return DrikaAnimation(function_json);
		case drika_billboard:
			return DrikaBillboard(function_json);
		case drika_read_write_savefile:
			return DrikaReadWriteSaveFile(function_json);
		case drika_comment:
			return DrikaComment(function_json);
		case drika_dialogue:
			return DrikaDialogue(function_json);
		case drika_ai_control:
			return DrikaAIControl(function_json);
	}
	return DrikaElement();
}
