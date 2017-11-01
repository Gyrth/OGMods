void DrawGUI() {
    Display();
}

void Init(string str){
    ReadAnimationList();
    QueryAnimation("");
}

void ReadAnimationList(){
    for(uint i = 0; i < 432; i++){
        if(level.GetPath("animation" + i) != ""){
            all_animation_paths.insertLast(level.GetPath("animation" + i));
        }else{
            return;
        }
    }
}

array<string> all_animation_paths;
array<string> animation_paths;
bool show = true;
int voice_preview = 1;
bool select = false;
int icon_size = 35;
int scrollbar_width = 10;
int padding = 10;
bool open_header = true;
int top_bar_height = 32;
bool post_init_done = false;

void QueryAnimation(string query){
    animation_paths.resize(0);
    for(uint i = 0; i < all_animation_paths.size(); i++){
        if(ToLowerCase(all_animation_paths[i]).findFirst(ToLowerCase(query)) != -1){
            animation_paths.insertLast(all_animation_paths[i]);
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
    if(show){
        ImGui_Begin("Animation Browser", show, ImGuiWindowFlags_NoScrollbar);
        ImGui_BeginChild(99, vec2(ImGui_GetWindowWidth(), top_bar_height), false, ImGuiWindowFlags_AlwaysUseWindowPadding | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);
        ImGui_Columns(2, false);
        if(ImGui_InputText("Search", ImGuiInputTextFlags_AutoSelectAll)){
            QueryAnimation(ImGui_GetTextBuf());
        }
        ImGui_NextColumn();
        ImGui_DragInt("Icon Size", icon_size, 1.0f, 35, 500, "%.0f");
        ImGui_EndChild();

        ImGui_PushStyleColor(ImGuiCol_FrameBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
        if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth() - scrollbar_width, ImGui_GetWindowHeight() - (top_bar_height + 30)), ImGuiWindowFlags_AlwaysAutoResize)){
            ImGui_PopStyleColor(2);
            AddCategory("Animations", animation_paths);
            ImGui_EndChildFrame();
        }
        ImGui_End();
    }
}

void AddCategory(string category, array<string> items){
    if(animation_paths.size() < 1){
        return;
    }
    ImGui_PushStyleColor(ImGuiCol_Border, vec4(0.0f, 0.5f, 0.5f, 0.5f));
    ImGui_PushStyleColor(ImGuiCol_Header, vec4(1.0f, 0.5f, 0.0f, 0.5f));
    if(ImGui_TreeNodeEx(category, ImGuiTreeNodeFlags_CollapsingHeader | ImGuiTreeNodeFlags_DefaultOpen)){
        ImGui_Unindent(32.0f);
        ImGui_BeginChild(category, vec2(ImGui_GetWindowWidth(), icon_size), false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoInputs);
        float row_size = 0.0f;
        for(uint i = 0; i < items.size(); i++){
            row_size += icon_size + padding;
            if(row_size > ImGui_GetWindowWidth()){
                row_size = icon_size + padding;
                ImGui_EndChild();
                ImGui_BeginChild("child " + i, vec2(ImGui_GetWindowWidth(), icon_size), false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoInputs);
                ImGui_Separator();
            }
            AddItem(items[i], i);
        }
        ImGui_EndChild();
        ImGui_Indent(32.0f);
        ImGui_TreePop();
    }
    ImGui_PopStyleColor();
}

void AddItem(string name, int index){
    ImGui_PushStyleColor(ImGuiCol_ChildWindowBg, vec4(1.0f, 0.0f, 1.0f, 0.1f));
    ImGui_BeginChild(name + "button" + index, vec2(ImGui_GetWindowWidth(), icon_size), false, ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_ShowBorders);
    /*if(ImGui_Selectable(name, false, ImGuiSelectableFlags_SpanAllColumns, vec2(ImGui_GetWindowWidth(), icon_size))){*/
    if(ImGui_Button(animation_paths[index], vec2(ImGui_GetWindowWidth(),icon_size))){
        ReceiveMessage("set_animation " + name);
    }
    ImGui_EndChild();
    ImGui_PopStyleColor();
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
        if(!post_init_done){
            vec3 pos = player.position;
            player.ReceiveScriptMessage("set_dialogue_position "+pos.x+" "+pos.y+" "+pos.z);
            player.ReceiveMessage("set_dialogue_control true");
            post_init_done = true;
        }
        token_iter.FindNextToken(msg);
        player.rigged_object().anim_client().Reset();
        player.ReceiveMessage("set_animation " + token_iter.GetToken(msg));
    }
}

void Update(){

}

bool HasFocus(){
    return false;
}
