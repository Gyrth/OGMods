void DrawGUI() {
	Display();
}

array<SpawnerItem> all_items;
array<SpawnerItem> query_result;

void Init(string str){
	all_items = ModGetAllSpawnerItems();
	QuerySpawnerItems("");
}

bool spawn = false;
string default_object_path = "Data/Objects/placeholder/empty_placeholder.xml";
string load_item_path = "";

void Update(int paused){
	if(GetInputPressed(0, "mouse0")){
	/*if(ImGui_IsMouseClicked(0)){*/
		if(spawn){
			Print(camera.GetMouseRay() + "spawn\n");
			int id = -1;
			if(load_item_path != ""){
				 id = CreateObject(load_item_path);
			}else{
				id = CreateObject(default_object_path);
			}
			load_item_path = "";
			Object@ obj = ReadObjectFromID(id);
			obj.SetTranslation(camera.GetPos() + (camera.GetMouseRay() * 5.0f));
			obj.SetSelectable(true);
			obj.SetTranslatable(true);
			obj.SetScalable(true);
			obj.SetRotatable(true);
			obj.SetDeletable(true);
			UnmarkAll();
		}
		spawn = false;
	}
}

void QuerySpawnerItems(string query){
	query_result.resize(0);
	for(uint i = 0; i < all_items.size(); i++){
		if(ToLowerCase(all_items[i].GetTitle()).findFirst(ToLowerCase(query)) != -1){
			query_result.insertLast(all_items[i]);
		}
	}
	toggles.resize(query_result.size());
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

bool show = true;
int voice_preview = 1;
bool select = false;
int icon_size = 155;
int title_height = 10;
int scrollbar_width = 10;
int padding = 10;
array<bool> toggles;
bool open_header = true;
int top_bar_height = 32;

void Display(){
	if(show){
		ImGui_Begin("Spawner", show, ImGuiWindowFlags_NoScrollbar);
		ImGui_BeginChild(99, vec2(ImGui_GetWindowWidth(), top_bar_height), false, ImGuiWindowFlags_AlwaysUseWindowPadding | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);
		ImGui_Columns(3, false);
		if(ImGui_InputText("Search", ImGuiInputTextFlags_AutoSelectAll)){
			QuerySpawnerItems(ImGui_GetTextBuf());
		}
		ImGui_NextColumn();
		if(ImGui_Button("Load Item...")){
			string path = GetUserPickedReadPath("xml", "Data/Objects");
			if(path != ""){
				ReceiveMessage("load_object \""+path+"\"");
			}
		}
		ImGui_NextColumn();
		ImGui_DragInt("Icon Size", icon_size, 1.0f, 75, 500, "%.0f");
		ImGui_EndChild();

		ImGui_PushStyleColor(ImGuiCol_FrameBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
		if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth() - scrollbar_width, ImGui_GetWindowHeight() - (top_bar_height + 30)), ImGuiWindowFlags_AlwaysAutoResize)){
			ImGui_PopStyleColor(2);
			AddCategory("category1", query_result);
			ImGui_EndChildFrame();
		}
		ImGui_End();
	}
}

void AddCategory(string category, array<SpawnerItem> items){
	if(items.size() < 1){
		return;
	}
	ImGui_PushStyleColor(ImGuiCol_Border, vec4(0.0f, 0.5f, 0.5f, 0.5f));
	ImGui_PushStyleColor(ImGuiCol_Header, vec4(1.0f, 0.5f, 0.0f, 0.5f));
	if(ImGui_TreeNodeEx(category, ImGuiTreeNodeFlags_CollapsingHeader | ImGuiTreeNodeFlags_DefaultOpen)){
		ImGui_Unindent(30.0f);
		ImGui_BeginChild(category, vec2(ImGui_GetWindowWidth(), icon_size), false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoInputs);
		float row_size = 0.0f;
		for(uint i = 0; i < items.size(); i++){
			row_size += icon_size + padding;
			if(row_size > ImGui_GetWindowWidth()){
				row_size = icon_size + padding;
				ImGui_EndChild();
				ImGui_Separator();
				ImGui_Indent(30.0f);
				ImGui_Unindent(30.0f);
				ImGui_BeginChild("child " + i, vec2(ImGui_GetWindowWidth(), icon_size), false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoInputs);
			}
			ImGui_SameLine();
			AddItem(items[i], i);
		}
		ImGui_EndChild();
		ImGui_Indent(30.0f);
		ImGui_TreePop();
	}
	ImGui_PopStyleColor();
}

void AddItem(SpawnerItem item, int index){
	ImGui_PushStyleColor(ImGuiCol_ChildWindowBg, vec4(1.0f, 0.0f, 1.0f, 0.1f));
	ImGui_BeginChild(item.GetTitle() + "button" + index, vec2(icon_size), false, ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_ShowBorders);

	ImGui_Text(item.GetTitle());

	TextureAssetRef image_texture = LoadTexture("Data/UI/spawner/thumbs/Static Objects/sphere_crete_rubble.png");
	/*TextureAssetRef image_texture = LoadTexture(item.GetThumbnail());*/

	if(toggles[index]){
		ImGui_PushStyleColor(ImGuiCol_Button, vec4(1.0f, 0.0f, 1.0f, 0.5f));
	}
	else{
		ImGui_PushStyleColor(ImGuiCol_Button, vec4(0.0f));
	}

	if (ImGui_ImageButton(image_texture, vec2(icon_size - title_height,icon_size - title_height), vec2(0,0), vec2(1,1), 0, vec4(0))){
		if(toggles[index]){
			spawn = false;
		}else{
			ReceiveMessage("load_object " + item.GetPath());
			UnmarkAll();
			spawn = true;
		}
		toggles[index] = !toggles[index];
	}
	ImGui_PopStyleColor();

	ImGui_EndChild();
	ImGui_PopStyleColor();
}

void UnmarkAll(){
	for(uint i = 0; i < toggles.size(); i++){
		toggles[i] = false;
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
	if(token == "load_object"){
		token_iter.FindNextToken(msg);
		load_item_path = token_iter.GetToken(msg);
		spawn = true;
	}
}
