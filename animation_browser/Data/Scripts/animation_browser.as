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
bool show = true;
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
	if(show){
		animation_index = 0;
		ImGui_SetNextWindowSize(vec2(500, 500), ImGuiSetCond_FirstUseEver);
		ImGui_Begin("Animation Browser", show, ImGuiWindowFlags_NoScrollbar);

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
		if(ImGui_InputText("Search", ImGuiInputTextFlags_AutoSelectAll)){
			search_buffer = ImGui_GetTextBuf();
			QueryAnimation(ImGui_GetTextBuf());
		}
		ImGui_EndChild();

		//Set the dialogue buffer again so that it doesn't take the buffer of the search.
		ImGui_SetTextBuf(dialogue_buffer);

		ImGui_PushStyleColor(ImGuiCol_FrameBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
		if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth() - scrollbar_width, ImGui_GetWindowHeight() - (top_bar_height + 30)), ImGuiWindowFlags_AlwaysAutoResize)){
			ImGui_PopStyleColor();
			for(uint i = 0; i < current_animations.size(); i++){
				AddCategory(current_animations[i].name, current_animations[i].animations);
			}
			ImGui_EndChildFrame();
		}
		//When the animation browser window isn't in focus and the dialogue editor is not on a line with a set_animation line then just hide the animation browser.
		if(!ImGui_IsRootWindowOrAnyChildFocused() && !on_animation_line){
			show = false;
		}
		ImGui_End();
	}
}

void AddCategory(string category, array<string> items){
	if(current_animations.size() < 1){
		return;
	}
	ImGui_PushStyleColor(ImGuiCol_Border, vec4(0.0f, 0.5f, 0.5f, 0.5f));
	ImGui_PushStyleColor(ImGuiCol_Header, vec4(1.0f, 0.5f, 0.0f, 0.5f));
	if(ImGui_TreeNodeEx(category, ImGuiTreeNodeFlags_CollapsingHeader | ImGuiTreeNodeFlags_DefaultOpen)){
		ImGui_Unindent(22.0f);
		for(uint i = 0; i < items.size(); i++){
			AddItem(items[i], animation_index);
			animation_index++;
		}
		ImGui_Indent(22.0f);
		ImGui_TreePop();
	}
	ImGui_PopStyleColor(2);
}

void AddItem(string name, int index){
	bool is_selected = name == selected_animation;
	if(ImGui_SelectableToggle(name, is_selected, 0, vec2(ImGui_GetWindowWidth(), 0.0) )){
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
	array<string> split_dialogue = dialogue_buffer.split("\n");
	array<string> split_line = split_dialogue[previous_dialogue_line].split(" ");
	if(split_line.size() >= 3){
		if(split_line[2] == "\"set_animation"){
			string new_line = split_line[0] + " " + split_line[1] + " " + split_line[2] + " " + "\\\""+ selected_animation +"\\\"\"";
			split_dialogue[previous_dialogue_line] = new_line;
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

		//send_character_message 1 "set_animation \"Data/Animations/r_dialogue_thoughtful.anm\""

		array<string> split_line = split_dialogue[current_dialogue_line].split(" ");
		if(split_line.size() >= 3){
			if(split_line[2] == "\"set_animation"){
				selected_animation = GetAnimationPathFromString(split_line[3]);
				on_animation_line = true;
				show = true;
				return;
			}
		}
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
