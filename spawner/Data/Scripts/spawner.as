void DrawGUI() {
	Display();
}

bool show = false;
int voice_preview = 1;
bool select = false;
int icon_size = 155;
int title_height = 10;
int scrollbar_width = 10;
int padding = 10;
bool open_header = true;
int top_bar_height = 32;
bool spawn = false;
string currently_selected = "";
string load_item_path = "";
array<string> category_names;
array<array<SpawnerItem>> sorted_items;
array<SpawnerItem> all_items;
array<SpawnerItem> query_result;

void Init(string str){
	all_items = ModGetAllSpawnerItems();
	QuerySpawnerItems("");
}

void Update(int paused){
	if(EditorModeActive()){
		if(GetInputPressed(0, "mouse0")){
		/*if(ImGui_IsMouseClicked(0)){*/
			if(spawn){
				int id = -1;
				if(FileExists(load_item_path)){
					id = CreateObject(load_item_path);
					Object@ obj = ReadObjectFromID(id);
					obj.SetTranslation(camera.GetPos() + (camera.GetMouseRay() * 5.0f));
					obj.SetSelectable(true);
					obj.SetTranslatable(true);
					obj.SetScalable(true);
					obj.SetRotatable(true);
					obj.SetDeletable(true);
					DeselectAll();
					obj.SetSelected(true);
				}else{
					DisplayError("Error", "This xml file does not exist: " + load_item_path);
				}
				Log(info, "Creating object " + load_item_path);
				load_item_path = "";
				currently_selected = "";
				spawn = false;
			}
		}else if(GetInputPressed(0, "i")){
			show = !show;
		}
	}else if(show){
		show = false;
	}
}

void QuerySpawnerItems(string query){
	query_result.resize(0);
	for(uint i = 0; i < all_items.size(); i++){
		if(ToLowerCase(all_items[i].GetTitle()).findFirst(ToLowerCase(query)) != -1 || ToLowerCase(all_items[i].GetCategory()).findFirst(ToLowerCase(query)) != -1){
			query_result.insertLast(all_items[i]);
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

void SortIntoCategories(){
	category_names.resize(0);
	sorted_items.resize(0);

	for(uint i = 0; i < query_result.size(); i++){
		int category_index = category_names.find(query_result[i].GetCategory());
		if(category_index == -1){
			category_names.insertLast(query_result[i].GetCategory());
			array<SpawnerItem> new_category = {query_result[i]};
			sorted_items.insertLast(new_category);
		}else{
			sorted_items[category_index].insertLast(query_result[i]);
		}
	}
}

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
			load_item_path = path;
			spawn = true;
		}
		ImGui_NextColumn();
		ImGui_DragInt("Icon Size", icon_size, 1.0f, 75, 500, "%.0f");
		ImGui_EndChild();

		ImGui_PushStyleColor(ImGuiCol_FrameBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
		if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth() - scrollbar_width, ImGui_GetWindowHeight() - (top_bar_height + 30)), ImGuiWindowFlags_AlwaysAutoResize)){
			ImGui_PopStyleColor(2);
			SortIntoCategories();
			for(uint i = 0; i < category_names.size(); i++){
				AddCategory(category_names[i], sorted_items[i]);
			}
			TextureAssetRef youdied_texture = LoadTexture("Data/Images/youdied.png");
			ImGui_Image(youdied_texture, vec2(ImGui_GetWindowWidth(), ImGui_GetWindowWidth() / 4.75f));
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

	/*TextureAssetRef image_texture = LoadTexture("Data/UI/spawner/thumbs/Static Objects/sphere_crete_rubble.png");*/
	TextureAssetRef image_texture = LoadTexture(item.GetThumbnail());

	if(currently_selected == item.GetTitle()){
		ImGui_PushStyleColor(ImGuiCol_Button, vec4(1.0f, 0.0f, 1.0f, 0.5f));
	}
	else{
		ImGui_PushStyleColor(ImGuiCol_Button, vec4(0.0f));
	}

	if (ImGui_ImageButton(image_texture, vec2(icon_size - title_height,icon_size - title_height))){
		if(currently_selected == item.GetTitle()){
			currently_selected = "";
			spawn = false;
		}else{
			currently_selected = item.GetTitle();
			load_item_path = item.GetPath();
			spawn = true;
		}
	}
	ImGui_PopStyleColor();
	ImGui_EndChild();
	ImGui_PopStyleColor();
}
