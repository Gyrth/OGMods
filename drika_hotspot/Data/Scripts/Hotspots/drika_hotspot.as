#include "drika_json_functions.as"
#include "drika_animation_group.as"
#include "hotspots/drika_element.as"
#include "drika_target_select.as"
#include "drika_go_to_line_select.as"
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
#include "hotspots/drika_user_interface.as"

bool show_editor = false;
bool run_in_editormode = true;
bool has_closed = true;
bool editing = false;
bool show_name = false;
string display_name = "Drika Hotspot";
bool script_finished = false;
int current_line;
array<DrikaElement@> drika_elements;
array<DrikaElement@> parallel_elements;
array<int> drika_indexes;
Object@ this_hotspot = ReadObjectFromID(hotspot.GetID());
string param_delimiter = "|";
array<string> messages;
bool is_selected = false;
array<ObjectReference@> object_references;
string default_preview_mesh = "Data/Objects/primitives/edged_cone.xml";
bool duplicating_hotspot = false;
bool duplicating_function = false;
bool exporting = false;
bool importing = false;
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
array<DrikaElement@> post_init_queue;
bool element_added = false;
array<int> multi_select;
string file_content;
int ui_snap_scale = 20;
int unique_id_counter = 0;
array<DrikaElement@> imported_elements;

array<DrikaAnimationGroup@> all_animations;
array<DrikaAnimationGroup@> current_animations;
array<string> active_mods;

const int _movement_state = 0;  // character is moving on the ground
const int _ground_state = 1;  // character has fallen down or is raising up, ATM ragdolls handle most of this
const int _attack_state = 2;  // character is performing an attack
const int _hit_reaction_state = 3;  // character was hit or dealt damage to and has to react to it in some manner
const int _ragdoll_state = 4;  // character is falling in ragdoll mode

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
	current_line = 0;
	show_name = (this_hotspot.GetName() != "");
	display_name = this_hotspot.GetName();
    level.ReceiveLevelEvents(hotspot.GetID());
	LoadPalette();
	SortFunctionsAlphabetical();
	//When the user duplicates a hotspot the editormode is active and the left alt is pressed.
	if(EditorModeActive() && GetInputDown(0, "lalt")){
		duplicating_hotspot = true;
	}else if(EditorModeActive() && GetInputDown(0, "lctrl") && GetInputDown(0, "v")){
		duplicating_hotspot = true;
	}
	InterpData();
}

void LoadPalette(bool use_defaults = false){
	JSON data;

	SavedLevel@ saved_level = save_file.GetSavedLevel("drika_data");
	string palette_data = saved_level.GetValue("drika_palette");

	if(palette_data == "" || !data.parseString(palette_data) || use_defaults){
		if(!data.parseString(palette_data)){
			Log(warning, "Unable to parse the JSON in the palette!");
		}
		data.parseFile("Data/Scripts/drika_default_palette.json");
	}

	display_colors.resize(drika_element_names.size());
	JSONValue color_palette = data.getRoot();
	for(uint i = 0; i < drika_element_names.size(); i++){
		if(i < color_palette.size()){
			JSONValue color = color_palette[i];
			vec4 palette_color = vec4(color[0].asFloat(), color[1].asFloat(), color[2].asFloat(), color[3].asFloat());
			display_colors[i] = palette_color;
		}else{
			display_colors[i] = vec4(1.0);
		}
	}
}

void QueryAnimation(string query){
	current_animations.resize(0);
	for(uint i = 0; i < all_animations.size(); i++){
		DrikaAnimationGroup@ current_group = all_animations[i];
		DrikaAnimationGroup new_group(current_group.name);
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
		}else if(GetCurrentElement().connection_types.find(other.GetType()) != -1){
			return true;
		}
	}
	return false;
}

bool ConnectTo(Object @other){
	if(drika_elements.size() > 0){
		bool return_value = GetCurrentElement().ConnectTo(other);
		Save();
		return return_value;
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

void Dispose() {
    level.StopReceivingLevelEvents(hotspot.GetID());
	if(editing && drika_elements.size() > 0){
		GetCurrentElement().EditDone();
	}
	if(GetInputDown(0, "delete")){
		for(uint i = 0; i < drika_elements.size(); i++){
			drika_elements[i].Delete();
			drika_elements[i].deleted = true;
		}
	}
}

void SetParameters(){
	params.AddIntCheckbox("Debug Current Line", debug_current_line);
	debug_current_line = (params.GetInt("Debug Current Line") == 1);
	params.AddIntCheckbox("Show UI Grid", show_grid);
	show_grid = (params.GetInt("Debug Current Line") == 1);
	params.AddInt("UI Snap Scale", ui_snap_scale);
	ui_snap_scale = params.GetInt("UI Snap Scale");
	params.AddIntCheckbox("Run in EditorMode", run_in_editormode);
	run_in_editormode = (params.GetInt("Run in EditorMode") == 1);
}

void InterpData(){
	int line_index = 0;
	if(params.HasParam("Script Data")){
		JSON data;
		if(!data.parseString(params.GetString("Script Data"))){
			Log(warning, "Unable to parse the JSON in the Script Data!");
		}else{
			for( uint i = 0; i < data.getRoot()["functions"].size(); ++i ) {
				DrikaElement@ new_element = InterpElement(none, data.getRoot()["functions"][i]);
				drika_elements.insertLast(@new_element);
				drika_indexes.insertLast(drika_elements.size() - 1);
				line_index += 1;
				post_init_queue.insertLast(@new_element);
			}
		}
	}
	Log(info, "Interp of script done. Hotspot number: " + this_hotspot.GetID());
	ReorderElements();
}

void LaunchCustomGUI(){
	show_editor = !show_editor;
	if(show_editor){
		update_scroll = true;
		multi_select = {current_line};
		level.SendMessage("drika_hotspot_editing " + this_hotspot.GetID());
		has_closed = false;
		if(drika_elements.size() > 0){
			GetCurrentElement().StartEdit();
		}
	}
}

void Update(){
	if(!run_in_editormode && EditorModeActive()){
		return;
	}
	//The post init queue is necessary so that Update is executing it, and not the Draw functions.
	//The Draw and DrawEditor sometimes can have issues such as spawning hotspots that crash the game.
	if(post_init_queue.size() > 0){
		for(uint i = 0; i < post_init_queue.size(); i++){
			post_init_queue[i].PostInit();
		}
		post_init_queue.resize(0);

		if(element_added || importing){
			element_added = false;
			ReorderElements();
			GetCurrentElement().StartEdit();
			Save();
		}

		duplicating_hotspot = false;
		duplicating_function = false;
		importing = false;
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
		}else if(!reorded){
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

bool reorded = false;
int display_index = 0;
bool update_scroll = false;
bool debug_current_line = false;
bool show_grid = true;
float left_over_drag_y = 0.0;
bool dragging = false;
bool open_palette = false;

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
		ImGui_Begin("Drika Hotspot" + (show_name?" - " + display_name:" " + this_hotspot.GetID()) + "###Drika Hotspot", show_editor, ImGuiWindowFlags_MenuBar);
		ImGui_PopStyleVar();

		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 150));
		ImGui_SetNextWindowSize(vec2(700.0f, 450.0f), ImGuiSetCond_FirstUseEver);

        if(ImGui_BeginPopupModal("Edit", ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse)){
			ImGui_BeginChild("Element Settings", vec2(-1, -1));
			ImGui_PushItemWidth(-1);
			GetCurrentElement().DrawSettings();
			ImGui_PopItemWidth();
			ImGui_EndChild();

			if(!ImGui_IsMouseHoveringAnyWindow() && ImGui_IsMouseClicked(0)){
				GetCurrentElement().ApplySettings();
				ImGui_CloseCurrentPopup();
				Save();
			}

			ImGui_EndPopup();
		}
		ImGui_PopStyleVar();

		if(open_palette){
			ImGui_OpenPopup("Configure Palette");
			open_palette = false;
		}

		ImGui_SetNextWindowSize(vec2(700.0f, 450.0f), ImGuiSetCond_FirstUseEver);
        if(ImGui_BeginPopupModal("Configure Palette", ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse)){
			if(ImGui_Button("Reset to defaults.")){
				LoadPalette(true);
				SavePalette();
			}
			ImGui_BeginChild("Palette", vec2(-1, -1));
			ImGui_PushItemWidth(-1);
			ImGui_Columns(2, false);
			ImGui_SetColumnWidth(0, 200.0);

			for(uint i = 0; i < sorted_element_names.size(); i++){
				drika_element_types current_element_type = drika_element_types(drika_element_names.find(sorted_element_names[i]));
				if(current_element_type == none){
					continue;
				}
				ImGui_PushStyleColor(ImGuiCol_Text, display_colors[current_element_type]);
				ImGui_Text(sorted_element_names[i]);
				ImGui_PopStyleColor();

				ImGui_NextColumn();
				ImGui_PushItemWidth(-1);
				ImGui_ColorEdit4("##Palette Color" + i, display_colors[current_element_type]);
				ImGui_PopItemWidth();
				ImGui_NextColumn();
			}

			ImGui_PopItemWidth();
			ImGui_EndChild();

			if(!ImGui_IsMouseHoveringAnyWindow() && ImGui_IsMouseClicked(0)){
				ImGui_CloseCurrentPopup();
				SavePalette();
			}

			ImGui_EndPopup();
		}

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

				if(ImGui_Checkbox("Run in EditorMode", run_in_editormode)){
					params.SetInt("Run in EditorMode", run_in_editormode?1:0);
				}

				if(ImGui_Checkbox("Show UI Grid", show_grid)){
					params.SetInt("Show UI Grid", show_grid?1:0);
					level.SendMessage("drika_set_show_grid " + show_grid);
				}

				if(ImGui_DragInt("UI Snap Scale", ui_snap_scale, 1.0, 15, 150, "%.0f")){
					params.SetInt("UI Snap Scale", ui_snap_scale);
					level.SendMessage("drika_set_ui_snap_scale " + ui_snap_scale);
				}

				if(ImGui_MenuItem("Configure Palette")){
					open_palette = true;
				}

				ImGui_EndMenu();
			}
			if(ImGui_BeginMenu("Import/Export")){
				if(ImGui_MenuItem("Export to file")){
					exporting = true;
					ExportToFile();
					exporting = false;
				}
				if(ImGui_MenuItem("Import from file")){
					ImportFromFile();
				}
				if(ImGui_MenuItem("Copy to clipboard")){
					exporting = true;
					CopyToClipBoard();
					exporting = false;
				}
				if(ImGui_MenuItem("Paste from clipboard")){
					PasteFromClipboard();
				}
				ImGui_EndMenu();
			}
			if(ImGui_ImageButton(delete_icon, vec2(10), vec2(0), vec2(1), 5, vec4(0))){
				if(drika_elements.size() > 0){
					GetCurrentElement().EditDone();
					array<int> sorted_selected = multi_select;
					sorted_selected.sortAsc();
					for(uint i = 0; i < sorted_selected.size(); i++){
						DeleteDrikaElement(sorted_selected[i] - i);
					}
					multi_select.resize(0);

					ReorderElements();
					Save();
					if(drika_elements.size() > 0){
						multi_select = {current_line};
						display_index = drika_indexes[current_line];
					}
					if(drika_elements.size() > 0){
						GetCurrentElement().StartEdit();
					}
				}
			}
			if(ImGui_IsItemHovered()){
				ImGui_PushStyleColor(ImGuiCol_PopupBg, titlebar_color);
				ImGui_SetTooltip("Delete");
				ImGui_PopStyleColor();
			}
			if(ImGui_ImageButton(duplicate_icon, vec2(10), vec2(0), vec2(1), 5, vec4(0))){
				if(drika_elements.size() > 0){
					duplicating_function = true;
					int last_selected = multi_select[multi_select.size() - 1];
					array<int> sorted_selected = multi_select;
					multi_select.resize(0);
					sorted_selected.sortDesc();
					int insert_at = sorted_selected[0];

					GetCurrentElement().EditDone();

					for(uint i = 0; i < sorted_selected.size(); i++){
						DrikaElement@ target = drika_elements[drika_indexes[sorted_selected[i]]];
						DrikaElement@ new_element = InterpElement(target.drika_element_type, target.GetSaveData());
						// Temporary set the index to the original index, so it can be found later on.
						new_element.SetIndex(sorted_selected[i]);
						post_init_queue.insertLast(@new_element);

						multi_select.insertLast(insert_at + 1 + i);
						drika_elements.insertLast(new_element);
						drika_indexes.insertAt(insert_at + 1, drika_elements.size() - 1);
						display_index = drika_indexes[insert_at + 1];
					}

					for(uint i = insert_at + 1; i < drika_indexes.size(); i++){
						if(drika_elements[drika_indexes[i]].index == last_selected){
							current_line = i;
						}
					}

					element_added = true;
				}
			}
			if(ImGui_IsItemHovered()){
				ImGui_PushStyleColor(ImGuiCol_PopupBg, titlebar_color);
				ImGui_SetTooltip("Duplicate");
				ImGui_PopStyleColor();
			}
			ImGui_EndMenuBar();
		}

		if(!ImGui_IsPopupOpen("Edit") && !ImGui_IsPopupOpen("Palette")){
			if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_UpArrow))){
				if(current_line > 0){
					multi_select = {current_line - 1};
					GetCurrentElement().EditDone();
					display_index = drika_indexes[current_line - 1];
					current_line -= 1;
					update_scroll = true;
					GetCurrentElement().StartEdit();
				}
			}else if(ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_DownArrow))){
				if(current_line < int(drika_elements.size() - 1)){
					multi_select = {current_line + 1};
					GetCurrentElement().EditDone();
					display_index = drika_indexes[current_line + 1];
					current_line += 1;
					update_scroll = true;
					GetCurrentElement().StartEdit();
				}
			}
		}

		for(uint i = 0; i < drika_indexes.size(); i++){
			int item_no = drika_indexes[i];
			vec4 text_color = drika_elements[item_no].GetDisplayColor();
			ImGui_PushStyleColor(ImGuiCol_Text, text_color);
			bool line_selected = display_index == int(item_no) || multi_select.find(i) != -1;

			string display_string = drika_elements[item_no].line_number + drika_elements[item_no].GetDisplayString();
			display_string = join(display_string.split("\n"), "");
			float space_for_characters = ImGui_CalcTextSize(display_string).x;

			if(space_for_characters > ImGui_GetWindowContentRegionWidth()){
				display_string = display_string.substr(0, int(display_string.length() * (ImGui_GetWindowContentRegionWidth() / space_for_characters)) - 3) + "...";
			}

			if(ImGui_Selectable(display_string, line_selected, ImGuiSelectableFlags_AllowDoubleClick)){
				// This item has been selected that is inside multiselect, but no modifier key is pressed.
				if(multi_select.find(i) != -1 && !dragging && multi_select.size() > 1 && !GetInputDown(0, "lshift") && !GetInputDown(0, "lctrl")){
					multi_select = {i};
				}
			}

			if(ImGui_IsItemHovered() && ImGui_IsMouseClicked(0)){
				left_over_drag_y = 0.0;
				if(ImGui_IsMouseDoubleClicked(0)){
					if(drika_elements[drika_indexes[i]].has_settings){
						GetCurrentElement().StartSettings();
						ImGui_OpenPopup("Edit");
					}
				}else{
					if(GetInputDown(0, "lshift")){
						int starting_point = multi_select[multi_select.size() - 1];
						int ending_point = i;
						int direction = starting_point < ending_point?1:-1;

						for(int j = starting_point; true; j += direction){
							if(multi_select.find(j) == -1){
								multi_select.insertLast(j);
							}
							if(j == ending_point){
								break;
							}
						}
					}else if(GetInputDown(0, "lctrl")){
						int find_selected = multi_select.find(i);
						if(multi_select.size() == 0){
							multi_select.insertLast(i);
						}else if(find_selected != -1 && multi_select.size() != 1){
							multi_select.removeAt(find_selected);
							GetCurrentElement().EditDone();
							display_index = int(drika_indexes[multi_select[multi_select.size() - 1]]);
							current_line = int(multi_select[multi_select.size() - 1]);
							GetCurrentElement().StartEdit();
							continue;
						}else{
							multi_select.insertLast(i);
						}
					}else if(multi_select.find(i) == -1){
						multi_select = {i};
					}
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
			if(ImGui_IsItemActive()){
				float drag_dy = ImGui_GetMouseDragDelta(0).y + left_over_drag_y;
				bool can_drag_up = multi_select.find(0) == -1;
				bool can_drag_down = multi_select.find(drika_indexes.size() - 1) == -1;
				float drag_threshold = 17.0;

				if(drag_dy < -drag_threshold && can_drag_up){
					while(drag_dy < -drag_threshold && can_drag_up){
						// Dragging Up

						for(uint k = 0; k < drika_indexes.size(); k++){
							for(uint j = 0; j < multi_select.size(); j++){
								if(multi_select[j] == int(k)){
									SwapIndexes(k, k - 1);
									reorded = true;
								}
							}
						}

						for(uint j = 0; j < multi_select.size(); j++){
							multi_select[j] -= 1;
						}

						current_line -= 1;
						drag_dy += drag_threshold;
						can_drag_up = multi_select.find(0) == -1;
					}
					left_over_drag_y = drag_dy;
					ImGui_ResetMouseDragDelta();
				}else if(drag_dy > drag_threshold && can_drag_down){
					while(drag_dy > drag_threshold && can_drag_down){
						// Dragging Down

						for(int k = drika_indexes.size() - 1; k > -1; k--){
							for(uint j = 0; j < multi_select.size(); j++){
								if(multi_select[j] == int(k)){
									SwapIndexes(k, k + 1);
									reorded = true;
								}
							}
						}

						for(uint j = 0; j < multi_select.size(); j++){
							multi_select[j] += 1;
						}

						current_line += 1;
						drag_dy -= drag_threshold;
						can_drag_down = multi_select.find(drika_indexes.size() - 1) == -1;
					}
					left_over_drag_y = drag_dy;
					ImGui_ResetMouseDragDelta();
				}
			}
		}

		ImGui_End();
		if(drika_elements.size() > 0 && !reorded && post_init_queue.size() == 0){
			GetCurrentElement().DrawEditing();
		}

		if(ImGui_IsMouseDragging(0)){
			dragging = true;
		}else{
			dragging = false;
		}

		ImGui_PopStyleColor(18);
	}
	if(reorded && !ImGui_IsMouseDragging(0)){
		reorded = false;
		ReorderElements();
		Save();
	}
}

/* TextureAssetRef dialogue_background = LoadTexture("Data/Textures/ui/dialogue/dialogue_bg.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
TextureAssetRef dialogue_background_left = LoadTexture("Data/Textures/ui/dialogue/dialogue_bg-fade.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
TextureAssetRef dialogue_background_right = LoadTexture("Data/Textures/ui/dialogue/dialogue_bg-fade_reverse.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

void DrawDialogueTest(){
	float screen_height = GetScreenHeight();
	float screen_width = GetScreenWidth();

	float one_fourth_height = screen_height / 4.0;
	vec2 ratio = vec2(screen_width / 1920.0, screen_height / 1080.0);
	float one_third_width = screen_width / 3.0;

	ImGui_PushStyleColor(ImGuiCol_WindowBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
	ImGui_Begin("MouseBlockContainer", show_editor, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoBringToFrontOnFocus | ImGuiWindowFlags_NoInputs);

	ImGui_SetWindowFontScale(ratio.x * 6.0);
	float side_width = 300.0;
	uint32 background_color = ImGui_GetColorU32(vec4(1.0, 1.0, 1.0, 0.5));

	ImDrawList_AddImage(dialogue_background_left, vec2((100.0 * ratio.x) + 0.0, one_fourth_height * 3.0), vec2((side_width) * ratio.x, one_fourth_height * 4.0), vec2(0, 0), vec2(1, 1), background_color);
	ImDrawList_AddImage(dialogue_background, vec2((side_width) * ratio.x, one_fourth_height * 3.0), vec2(screen_width - (side_width * ratio.x), one_fourth_height * 4.0), vec2(0, 0), vec2(1, 1), background_color);
	ImDrawList_AddImage(dialogue_background_right, vec2((screen_width - (side_width * ratio.x)) - 0.0, one_fourth_height * 3.0), vec2(screen_width - (100 * ratio.x), one_fourth_height * 4.0), vec2(0, 0), vec2(1, 1), background_color);

	ImDrawList_AddText(vec2((side_width) * ratio.x, one_fourth_height * 3.0), ImGui_GetColorU32(vec4(1.0, 1.0, 1.0, 1.0)), "Example text\nThis could be the dialogue");
	ImGui_SetWindowFontScale(1.0);

	ImGui_PopStyleColor(1);

	ImGui_SetWindowPos("MouseBlockContainer", vec2(0, one_fourth_height * 3.0));
	ImGui_SetWindowSize("MouseBlockContainer", vec2(screen_width, screen_height));
	ImGui_End();
} */

void SavePalette(){
	JSON data;
	JSONValue palette;
	for(uint i = 0; i < display_colors.size(); i++){
		JSONValue color = JSONValue(JSONarrayValue);
		color.append(display_colors[i].x);
		color.append(display_colors[i].y);
		color.append(display_colors[i].z);
		color.append(display_colors[i].a);
		palette.append(color);
	}
	data.getRoot() = palette;
	SavedLevel@ saved_level = save_file.GetSavedLevel("drika_data");
	saved_level.SetValue("drika_palette", data.writeString(false));
	save_file.WriteInPlace();
}

void ExportToFile(){
	string write_path = GetUserPickedWritePath("txt", "Data/Dialogues");
	if(write_path != ""){
		Log(info,"Save to file: " + write_path);

		JSON data;
		JSONValue functions;
		array<int> target_indexes = drika_indexes;

		//Only export the selected functions.
		if(multi_select.size() > 1){
			array<int> sorted_selected = multi_select;
			sorted_selected.sortAsc();
			target_indexes = sorted_selected;
		}

		for(uint i = 0; i < target_indexes.size(); i++){
			drika_elements[target_indexes[i]].SetExportIndex(i);
		}

		for(uint i = 0; i < target_indexes.size(); i++){
			JSONValue function_data = drika_elements[target_indexes[i]].GetSaveData();
			function_data["function"] = JSONValue(drika_elements[target_indexes[i]].drika_element_type);
			functions.append(function_data);
		}

		for(uint i = 0; i < target_indexes.size(); i++){
			drika_elements[target_indexes[i]].ClearExportIndex();
		}

		data.getRoot()["functions"] = functions;
		string send_data = join(data.writeString(false).split("\""), "\\\"");
		level.SendMessage("drika_export_to_file " + write_path + " " + "\"" + send_data + "\"");
	}
}

void CopyToClipBoard(){
	Log(info,"Copy To Clipboard");

	JSON data;
	JSONValue functions;
	array<int> target_indexes = drika_indexes;

	//Only export the selected functions.
	if(multi_select.size() > 1){
		array<int> sorted_selected = multi_select;
		sorted_selected.sortAsc();
		target_indexes = sorted_selected;
	}

	for(uint i = 0; i < target_indexes.size(); i++){
		drika_elements[target_indexes[i]].SetExportIndex(i);
	}

	for(uint i = 0; i < target_indexes.size(); i++){
		JSONValue function_data = drika_elements[target_indexes[i]].GetSaveData();
		function_data["function"] = JSONValue(drika_elements[target_indexes[i]].drika_element_type);
		functions.append(function_data);
	}

	for(uint i = 0; i < target_indexes.size(); i++){
		drika_elements[target_indexes[i]].ClearExportIndex();
	}

	data.getRoot()["functions"] = functions;
	ImGui_SetClipboardText(data.writeString(false));
}

void PasteFromClipboard(){
	string clipboard_content = ImGui_GetClipboardText();
	InterpImportData(clipboard_content);
}

void ImportFromFile(){
	string read_path = GetUserPickedReadPath("txt", "Data/Dialogues");
	if(read_path != ""){
		read_path = read_path;
		level.SendMessage("drika_read_file " + hotspot.GetID() + " " + read_path + " " + "drika_import_from_file" + " " + 0);
	}
}

void DeleteDrikaElement(int index){
	DrikaElement@ target = drika_elements[drika_indexes[index]];

	target.Delete();
	target.deleted = true;

	for(uint i = 0; i < drika_indexes.size(); i++){
		if(drika_indexes[i] > drika_indexes[index]){
			drika_indexes[i] -= 1;
		}
	}

	drika_elements.removeAt(drika_indexes[index]);
	drika_indexes.removeAt(index);

	// If the last element is deleted then the target needs to be the previous element.
	if(current_line > 0 && current_line == int(drika_elements.size())){
		display_index = drika_indexes[current_line - 1];
		current_line -= 1;
	}else if(drika_elements.size() > 0){
		display_index = drika_indexes[current_line];
	}
}

void SwapIndexes(int index_1, int index_2){
	int value_1 = drika_indexes[index_1];
	drika_indexes[index_1] = drika_indexes[index_2];
	drika_indexes[index_2] = value_1;
}

DrikaElement@ GetCurrentElement(){
	return drika_elements[drika_indexes[current_line]];
}

void ReorderElements(){
	for(uint index = 0; index < drika_indexes.size(); index++){
		DrikaElement@ current_element = drika_elements[drika_indexes[index]];
		current_element.SetIndex(index);

		int item_no = drika_indexes[index];
		current_element.line_number = drika_elements[item_no].index + ".";
		int initial_length = max(1, (7 - current_element.line_number.length()));
		for(int j = 0; j < initial_length; j++){
			current_element.line_number += " ";
		}
	}

	for(uint index = 0; index < drika_indexes.size(); index++){
		DrikaElement@ current_element = drika_elements[drika_indexes[index]];
		current_element.ReorderDone();
	}
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
}

void ReceiveMessage(string msg){
    TokenIterator token_iter;
    token_iter.Init();
	token_iter.FindNextToken(msg);
	string token = token_iter.GetToken(msg);

    if(drika_elements.size() == 0 && token != "drika_read_file"){
        return;
    }
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

		DrikaAnimationGroup new_group(group_name);
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
		string param_1 = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		int param_2 = atoi(token_iter.GetToken(msg));

		string file_content = "";
		while(token_iter.FindNextToken(msg)){
			file_content += token_iter.GetToken(msg);
		}

		if(param_1 == "drika_import_from_file"){
			InterpImportData(file_content);
		}else{
			GetCurrentElement().ReceiveMessage(file_content, param_1, param_2);
		}
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
	}else if(token == "drika_ui_instruction"){
		array<string> instruction;

		while(token_iter.FindNextToken(msg)){
			instruction.insertLast(token_iter.GetToken(msg));
		}

		GetCurrentElement().ReadUIInstruction(instruction);
	}
}

void InterpImportData(string import_data){
	JSON data;
	duplicating_hotspot = true;
	array<int> created_indexes;
	importing = true;
	imported_elements.resize(0);

	if(!data.parseString(import_data)){
		Log(warning, "Unable to parse the JSON in the Script Data!");
		duplicating_hotspot = false;
		return;
	}else{
		int start_index = (drika_indexes.size() > 0)?current_line + 1:current_line;
		for( uint i = 0; i < data.getRoot()["functions"].size(); ++i ) {
			DrikaElement@ new_element = InterpElement(none, data.getRoot()["functions"][i]);
			drika_elements.insertLast(@new_element);
			drika_indexes.insertAt(start_index + i, drika_elements.size() - 1);
			created_indexes.insertLast(start_index + i);
			post_init_queue.insertLast(@new_element);
			imported_elements.insertLast(@new_element);
		}
	}

	if(drika_indexes.size() == 0){
		duplicating_hotspot = false;
		return;
	}

	multi_select = created_indexes;
	current_line = multi_select[multi_select.size() - 1];
	display_index = drika_indexes[current_line];
}

DrikaElement@ GetImportElement(int _index){
	if(int(imported_elements.size()) > _index){
		return imported_elements[_index];
	}else{
		return null;
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
	multi_select = {current_line};
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
		vec3 hotspot_position = this_hotspot.GetTranslation();
		char.ReceiveScriptMessage("set_dialogue_position " + hotspot_position.x + " " + hotspot_position.y + " " + hotspot_position.z);
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
			string trimmed_display_string = GetCurrentElement().GetDisplayString();
			trimmed_display_string = join(trimmed_display_string.split("\n"), "");
			if(trimmed_display_string.length() > 35){
				trimmed_display_string = trimmed_display_string.substr(0, 35) + "...";
			}
			DebugDrawText(this_hotspot.GetTranslation() + vec3(0, 0.75, 0), trimmed_display_string, 1.0, false, _delete_on_draw);
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
	DisposeTextAtlases();
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

string GetUniqueID(){
	unique_id_counter += 1;
	return hotspot.GetID() + "" + unique_id_counter;
}

void AddFunctionMenuItems(){
	for(uint i = 0; i < sorted_element_names.size(); i++){
		drika_element_types current_element_type = drika_element_types(drika_element_names.find(sorted_element_names[i]));
		if(current_element_type == none){
			continue;
		}
		ImGui_PushStyleColor(ImGuiCol_Text, display_colors[current_element_type]);
		if(ImGui_MenuItem(sorted_element_names[i])){
			DrikaElement@ new_element = InterpElement(current_element_type, JSONValue());
			post_init_queue.insertLast(@new_element);
			InsertElement(new_element);
			element_added = true;
			multi_select = {current_line};
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
		case drika_user_interface:
			return DrikaUserInterface(function_json);
	}
	return DrikaElement();
}
