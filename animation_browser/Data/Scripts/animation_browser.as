void DrawGUI() {
	Display();
}

void Init(string str){
	array<ModID> mod_ids = GetActiveModSids();
	for(uint i = 0; i < mod_ids.size(); i++){
		active_mods.insertLast(ModGetID(mod_ids[i]));
	}

	ReadAnimationList();
	QueryAnimation("");
}

array<AnimationGroup@> all_animations;
array<AnimationGroup@> current_animations;
array<string> active_mods;
bool show_animation_browser = false;
bool show_pick_animation_button = false;
int voice_preview = 1;
bool select = false;
int icon_size = 25;
int scrollbar_width = 10;
int padding = 10;
bool open_header = true;
int top_bar_height = 32;
const int _ragdoll_state = 4;
int animation_index = 0;
string selected_animation = "";
int dialogue_character_position = 0;
int current_dialogue_line = 0;
int previous_dialogue_line = 0;
bool on_animation_line = false;

string search_buffer = "";
string dialogue_buffer = "";
bool update_dialogue_buffer = false;

// Coloring options
vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);
vec4 background_color(0.25, 0.25, 0.25, 0.98);
vec4 titlebar_color(0.15, 0.15, 0.15, 0.98);
vec4 item_hovered(0.2, 0.2, 0.2, 0.98);
vec4 item_clicked(0.1, 0.1, 0.1, 0.98);
vec4 text_color(0.7, 0.7, 0.7, 1.0);

class AnimationGroup{
	string name;
	array<string> animations;
	AnimationGroup(string _name){
		name = _name;
	}
	void AddAnimation(string _animation){
		animations.insertLast(_animation);
	}
}

void ReadAnimationList(){
	JSON file;
	file.parseFile("Data/Scripts/animation_browser_paths.json");
	JSONValue root = file.getRoot();
	array<string> list_groups = root.getMemberNames();
	for(uint i = 0; i < list_groups.size(); i++){
		//Skip this mod if it's not active_slider
		if(active_mods.find(root[list_groups[i]]["Mod ID"].asString()) == -1){
			continue;
		}
		AnimationGroup new_group(list_groups[i]);
		JSONValue animation_list = root[list_groups[i]]["Animations"];
		for(uint j = 0; j < animation_list.size(); j++){
			string new_animation = animation_list[j].asString();
			if(FileExists(new_animation)){
				//This animation exists in the game fils so add it to the animation group.
				new_group.AddAnimation(new_animation);
			}
		}
		all_animations.insertLast(@new_group);
	}
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

void Display(){
	UpdateCursor();

	ImGui_PushStyleColor(ImGuiCol_WindowBg, background_color);
	ImGui_PushStyleColor(ImGuiCol_PopupBg, background_color);
	ImGui_PushStyleColor(ImGuiCol_TitleBg, background_color);
	ImGui_PushStyleColor(ImGuiCol_TitleBgActive, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_TitleBgCollapsed, background_color);
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

	ImGui_PushStyleColor(ImGuiCol_CheckMark, text_color);
	ImGui_PushStyleColor(ImGuiCol_TextSelectedBg, titlebar_color);

	ImGui_PushStyleColor(ImGuiCol_SliderGrab, item_clicked);
	ImGui_PushStyleColor(ImGuiCol_SliderGrabActive, titlebar_color);

	ImGui_PushStyleColor(ImGuiCol_FrameBg, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_FrameBgHovered, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_FrameBgActive, item_clicked);

	ImGui_PushStyleColor(ImGuiCol_ResizeGrip, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_ResizeGripHovered, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_ResizeGripActive, item_clicked);

	if(show_pick_animation_button){
		if(ImGui_Begin("###Dialogue Editor", show_pick_animation_button, ImGuiWindowFlags_MenuBar)){
			if(ImGui_BeginMenuBar()){
				if(ImGui_Button("Pick Animation")){
					show_animation_browser = true;
				}
				ImGui_EndMenuBar();
			}
			ImGui_End();
		}
	}

	if(show_animation_browser){
		ImGui_SetNextWindowSize(vec2(500, 500), ImGuiSetCond_FirstUseEver);
		if(ImGui_Begin("Animation Browser", show_animation_browser, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoCollapse)){
			ImGui_BeginChild(99, vec2(ImGui_GetWindowWidth(), top_bar_height), false, ImGuiWindowFlags_AlwaysUseWindowPadding | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);

			if(update_dialogue_buffer){
				update_dialogue_buffer = false;
				ImGui_SetTextBuf(dialogue_buffer);

				level.Execute(	"int previous_selected_line = dialogue.selected_line;" +
								"dialogue.ClearSpawnedObjects();" +
								"dialogue.UpdateStringsFromScript(ImGui_GetTextBuf());" +
								"dialogue.AddInvisibleStrings();" +
								"dialogue.modified = true;" +
								"dialogue.selected_line = previous_selected_line;" +
								"dialogue.HandleSelectedString(dialogue.selected_line);");
			}else{
				//If the dialogue buffer doesn't need to be updated then just request the current buffer content and set it again after the search buffer.
				dialogue_buffer = ImGui_GetTextBuf();
			}

			ImGui_SetTextBuf(search_buffer);
			ImGui_Text("Search");
			ImGui_SameLine();
			ImGui_PushItemWidth(ImGui_GetWindowWidth() - 85);
			if(ImGui_InputText("", ImGuiInputTextFlags_AutoSelectAll)){
				search_buffer = ImGui_GetTextBuf();
				QueryAnimation(ImGui_GetTextBuf());
			}
			ImGui_PopItemWidth();
			ImGui_EndChild();

			//Set the dialogue buffer again so that it doesn't take the buffer of the search.
			ImGui_SetTextBuf(dialogue_buffer);

			if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth() - scrollbar_width, ImGui_GetWindowHeight() - (top_bar_height + 40)), ImGuiWindowFlags_AlwaysAutoResize)){
				for(uint i = 0; i < current_animations.size(); i++){
					AddCategory(current_animations[i].name, current_animations[i].animations);
				}
				ImGui_EndChildFrame();
			}
			//When the animation browser window isn't in focus and the dialogue editor is not on a line with a set_animation line then just hide the animation browser.
			if(!ImGui_IsRootWindowOrAnyChildFocused() && !on_animation_line){
				show_animation_browser = false;
			}
			ImGui_End();
		}
	}

	ImGui_PopStyleColor(28);
}

void AddCategory(string category, array<string> items){
	if(current_animations.size() < 1){
		return;
	}
	if(ImGui_TreeNodeEx(category, ImGuiTreeNodeFlags_CollapsingHeader | ImGuiTreeNodeFlags_DefaultOpen)){
		for(uint i = 0; i < items.size(); i++){
			AddItem(items[i], animation_index);
			animation_index++;
		}
	}
}

void AddItem(string name, int index){
	bool is_selected = name == selected_animation;
	if(ImGui_Selectable(name, is_selected)){
		selected_animation = name;
		SetCurrentAnimation();
	}
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	if(!token_iter.FindNextToken(msg)){
		return;
	}
	string token = token_iter.GetToken(msg);
	if(token == "set_animation"){

	}
}

void SetCurrentAnimation(){
	int index = previous_dialogue_line;
	array<string> split_dialogue = dialogue_buffer.split("\n");
	array<string> split_line = split_dialogue[index].split(" ");

	if(split_line.size() >= 3){
		if(split_line[2] == "\"set_animation"){
			string new_line = split_line[0] + " " + split_line[1] + " " + split_line[2] + " " + "\\\""+ selected_animation +"\\\"\"";
			split_dialogue[index] = new_line;
			dialogue_buffer = join(split_dialogue, "\n");
			update_dialogue_buffer = true;
		}
	}
}

void Update(){

}

void UpdateCursor(){
	if(dialogue_character_position != imgui_text_input_CursorPos){
		//The cursor position has changed.
		previous_dialogue_line = current_dialogue_line;
		dialogue_character_position = imgui_text_input_CursorPos;
		dialogue_buffer = ImGui_GetTextBuf();

		array<string> split_dialogue = dialogue_buffer.split("\n");
		int new_dialogue_line = 0;
		int counter = 0;
		for(uint i = 0; i < split_dialogue.size(); i++){
			counter += split_dialogue[i].length() + 1;
			if(counter > dialogue_character_position){
				break;
			}
			new_dialogue_line += 1;
		}
		current_dialogue_line = new_dialogue_line;
		array<string> split_line = split_dialogue[current_dialogue_line].split(" ");
		if(split_line.size() >= 3){
			if(split_line[2] == "\"set_animation"){
				selected_animation = GetAnimationPathFromString(split_line[3]);
				on_animation_line = true;
				show_animation_browser = true;
				/* show_pick_animation_button = true; */
				return;
			}
		}
		/* show_pick_animation_button = false; */
		on_animation_line = false;
	}
}

string GetAnimationPathFromString(string input){
	string output;
	output = join(input.split("\\\""), "");
	output = join(output.split("\""), "");
	return output;
}

bool HasFocus(){
	return false;
}


bool DialogueCameraControl() {
	return false;
}
