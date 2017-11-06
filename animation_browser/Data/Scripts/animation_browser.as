void DrawGUI() {
    Display();
}

void Init(string str){
    ReadAnimationList();
    QueryAnimation("");
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
int currently_pressed = -1;
const int _ragdoll_state = 4;

void ReadAnimationList(){
    JSON file;
    file.parseFile("Data/Scripts/animation_browser_paths.json");
    JSONValue root = file.getRoot();
    array<string> list_animations = root.getMemberNames();
    for(uint i = 0; i < list_animations.size(); i++){
        string new_animation = root[list_animations[i]].asString();
        if(FileExists(new_animation)){
            /*Print("exists! " + new_animation + "\n");*/
            all_animation_paths.insertLast(new_animation);
        }
    }
}

void QueryAnimation(string query){
    animation_paths.resize(0);
    for(uint i = 0; i < all_animation_paths.size(); i++){
        if(ToLowerCase(all_animation_paths[i]).findFirst(ToLowerCase(query)) != -1){
            animation_paths.insertLast(all_animation_paths[i]);
        }
    }
    Print("results: " + animation_paths.size() + "\n");
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
        ImGui_SetNextWindowSize(vec2(500, 500), ImGuiSetCond_FirstUseEver);
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
            ImGui_PopStyleColor();
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
        ImGui_Unindent(22.0f);
        for(uint i = 0; i < items.size(); i++){
            AddItem(items[i], i);
        }
        ImGui_Indent(22.0f);
    }
    ImGui_PopStyleColor(2);
}

void AddItem(string name, int index){
    bool is_selected = index == currently_pressed;
    if(is_selected) {
        // From default style colors for ImGuiCol_Header, ImGuiCol_HeaderHovered, ImGuiCol_HeaderActive
        // There's ways to get these colors from the API, but it's a PITA,
        //   and there's no way in OG to easily globally override the default style anyway (yet)
        ImGui_PushStyleColor(ImGuiCol_Button, vec4(0.40f, 0.40f, 0.90f, 0.45f));
        ImGui_PushStyleColor(ImGuiCol_ButtonHovered, vec4(0.45f, 0.45f, 0.90f, 0.80f));
        ImGui_PushStyleColor(ImGuiCol_ButtonActive, vec4(0.53f, 0.53f, 0.87f, 0.80f));
    }
    if(ImGui_Button(animation_paths[index], vec2(ImGui_GetWindowWidth() - 50, icon_size))) {
        ReceiveMessage("set_animation " + name);
        currently_pressed = index;
    }
    if(is_selected) {
        ImGui_PopStyleColor(3);
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

void Update(){
    MovementObject@ player = ReadCharacter(0);
    if(GetInputPressed(player.GetID(), "8")){
        player.ReceiveMessage("set_dialogue_control false");
        show = false;
    }else if(GetInputPressed(player.GetID(), "escape")){
        show = true;
    }
}

bool HasFocus(){
    return false;
}
