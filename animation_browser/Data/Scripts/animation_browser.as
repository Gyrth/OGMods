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
int icon_size = 35;
int scrollbar_width = 10;
int padding = 10;
bool open_header = true;
int top_bar_height = 32;
const int _ragdoll_state = 4;
int animation_index = 0;
string selected_animation = "";

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
                Print("exists! " + new_animation + "\n");
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
    Print("results: " + current_animations.size() + "\n");
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

string buffer1 = "";
string buffer2 = "";
string dialogue_buffer = "";
bool update_dialogue_buffer = false;

void Display(){
	if(update_dialogue_buffer){
		Log(info, "Update diag");
		update_dialogue_buffer = false;
		ImGui_SetTextBuf(dialogue_buffer);
		level.Execute("dialogue.HandleSelectedString(" + previous_dialogue_line + ");");
	}else{
		dialogue_buffer = ImGui_GetTextBuf();
	}
    if(show){
        animation_index = 0;
        ImGui_SetNextWindowSize(vec2(500, 500), ImGuiSetCond_FirstUseEver | ImGuiWindowFlags_NoBringToFrontOnFocus);
        ImGui_Begin("Animation Browser", show, ImGuiWindowFlags_NoScrollbar);
        ImGui_BeginChild(99, vec2(ImGui_GetWindowWidth(), top_bar_height), false, ImGuiWindowFlags_AlwaysUseWindowPadding | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);
        ImGui_Columns(2, false);

		ImGui_SetTextBuf(buffer1);
        if(ImGui_InputText("Search", ImGuiInputTextFlags_AutoSelectAll)){
			buffer1 = ImGui_GetTextBuf();
            QueryAnimation(ImGui_GetTextBuf());
        }
		ImGui_SameLine();
		ImGui_SetTextBuf(buffer2);
		if(ImGui_InputText("Search2")){
			buffer2 = ImGui_GetTextBuf();
		}


        ImGui_NextColumn();
        ImGui_DragInt("Icon Size", icon_size, 1.0f, 35, 500, "%.0f");
        ImGui_EndChild();

        ImGui_PushStyleColor(ImGuiCol_FrameBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
        if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth() - scrollbar_width, ImGui_GetWindowHeight() - (top_bar_height + 30)), ImGuiWindowFlags_AlwaysAutoResize)){
            ImGui_PopStyleColor();
            for(uint i = 0; i < current_animations.size(); i++){
                AddCategory(current_animations[i].name, current_animations[i].animations);
            }
            ImGui_EndChildFrame();
        }
        ImGui_End();
    }
	ImGui_SetTextBuf(dialogue_buffer);
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
	if(ImGui_SelectableToggle(name, is_selected, 0, vec2(ImGui_GetWindowWidth(), icon_size) )){
		selected_animation = name;
		SetCurrentAnimation();
	}
}

void ReceiveMessage(string msg){
    Print("received " + msg + "\n");
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "set_animation"){
        MovementObject@ player = ReadCharacter(0);
        Object@ player_spawn = ReadObjectFromID(player.GetID());
        if(player.GetBoolVar("dialogue_control") != true || player.GetIntVar("state") == _ragdoll_state){
            player.Execute("WakeUp(_wake_stand); EndGetUp(); unragdoll_time = 0.0f;");
            vec3 pos = player_spawn.GetTranslation();
            player.ReceiveScriptMessage("set_dialogue_position "+pos.x+" "+pos.y+" "+pos.z);
            player.ReceiveMessage("set_dialogue_control true");
        }
        token_iter.FindNextToken(msg);
        string animation = token_iter.GetToken(msg);

        player.rigged_object().anim_client().Reset();
        player.Execute("ResetLayers();");
        player.ReceiveMessage("set_animation " + animation);
    }
}

void SetCurrentAnimation(){
	array<string> split_dialogue = dialogue_buffer.split("\n");
	array<string> split_line = split_dialogue[previous_dialogue_line].split(" ");
	Log(info, "Update diag " + previous_dialogue_line);
	if(split_line.size() >= 3){
		if(split_line[2] == "\"set_animation"){
			string new_line = split_line[0] + " " + split_line[1] + " " + split_line[2] + " " + "\\\""+ selected_animation +"\\\"";
			split_dialogue[previous_dialogue_line] = new_line;
			dialogue_buffer = join(split_dialogue, "\n");
			update_dialogue_buffer = true;
			/* level.SendMessage("save_selected_dialogue"); */
			/* level.Execute("dialogue.UpdateScriptFromStrings();"); */
		}
	}
}

int dialogue_character_position = 0;
int previous_character_position = 0;
int current_dialogue_line = 0;
int previous_dialogue_line = 0;

void Update(){
	if(dialogue_character_position != imgui_text_input_CursorPos){
		//The cursor position has changed.
		previous_dialogue_line = current_dialogue_line;
		previous_character_position = dialogue_character_position;

		dialogue_character_position = imgui_text_input_CursorPos;
		array<string> split_dialogue = dialogue_buffer.split("\n");
		int new_dialogue_line = 0;
		int counter = 0;
		for(uint i = 0; i < split_dialogue.size(); i++){
			counter += split_dialogue[i].length() + 1;
			Log(info, "Dialogue line " + split_dialogue[i]);
			if(counter > dialogue_character_position){
				break;
			}
			new_dialogue_line += 1;
		}
		current_dialogue_line = new_dialogue_line;
		//send_character_message 1 "set_animation \"Data/Animations/r_dialogue_facepalm.anm\""

		array<string> split_line = split_dialogue[current_dialogue_line].split(" ");
		if(split_line.size() >= 3){
			Log(info, "Dialogue line " + imgui_text_input_CursorPos + " " + current_dialogue_line + split_line[2]);
			if(split_line[2] == "\"set_animation"){
				show = true;
			}else{
				show = false;
			}
		}
	}
}

bool HasFocus(){
    return false;
}
