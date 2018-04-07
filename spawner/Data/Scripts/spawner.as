void DrawGUI() {
	Display();
}

bool show = false;
int voice_preview = 1;
bool select = false;
int icon_size = 155;
int title_height = 25;
int scrollbar_width = 10;
int padding = 10;
bool open_header = true;
int top_bar_height = 32;
bool spawn = false;
bool retrieved_item_list = false;
bool retrieved_thumbnails = false;
uint thumbnail_retrieve_index = 0;
string currently_selected = "";
string load_item_path = "";

TextureAssetRef youdied_texture = LoadTexture("Data/Images/youdied.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

TextureAssetRef default_texture = LoadTexture("Data/UI/spawner/hd-thumbs/Object/whaleman.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

array<GUISpawnerItem@> all_items;
array<GUISpawnerCategory@> categories;

class GUISpawnerItem{
	string title;
	string category;
	string path;
	uint id;
	TextureAssetRef icon;
	SpawnerItem spawner_item;

	GUISpawnerItem(string _category, string _title, string _path, int _id, TextureAssetRef _icon, SpawnerItem _spawner_item){
		category = _category;
		icon = _icon;
		spawner_item = _spawner_item;
		title = _title;
		path = _path;
		id = _id;
	}
	void SetThumbnail(){
		//If no thumbnail was set, use the default one.
		if(spawner_item.GetThumbnail() == ""){
			return;
		}else{
			icon = LoadTexture(spawner_item.GetThumbnail(), TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
		}
	}
}

void GetNextThumbnail(){
	all_items[thumbnail_retrieve_index].SetThumbnail();
	thumbnail_retrieve_index++;
	if(thumbnail_retrieve_index >= all_items.size()){
		retrieved_thumbnails = true;
		return;
	}
}

class GUISpawnerCategory{
	string category_name;
	array<GUISpawnerItem@> spawner_items;
	GUISpawnerCategory(string _category_name){
		category_name = _category_name;
	}
	void AddItem(GUISpawnerItem@ item){
		spawner_items.insertLast(@item);
	}
}

void Init(string str){

}

void GetAllSpawnerItems(){
	array<SpawnerItem> spawner_items = ModGetAllSpawnerItems();
	for(uint i = 0; i < spawner_items.size(); i++){
		TextureAssetRef icon_texture = default_texture;
		all_items.insertLast(@GUISpawnerItem(spawner_items[i].GetCategory(), spawner_items[i].GetTitle(), spawner_items[i].GetPath(), i, icon_texture, spawner_items[i]));
	}
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
					obj.SetCopyable(true);
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
		if(show && !retrieved_item_list){
			GetAllSpawnerItems();
			categories = SortIntoCategories(QuerySpawnerItems(""));
			retrieved_item_list = true;
		}else if (show && !retrieved_thumbnails){
			GetNextThumbnail();
		}
	}else if(show){
		show = false;
	}
}

array<GUISpawnerItem@> QuerySpawnerItems(string query){
	array<GUISpawnerItem@> new_list;
	for(uint i = 0; i < all_items.size(); i++){
		if(ToLowerCase(all_items[i].title).findFirst(ToLowerCase(query)) != -1 || ToLowerCase(all_items[i].category).findFirst(ToLowerCase(query)) != -1){
			new_list.insertLast(@all_items[i]);
		}
	}
	return new_list;
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

array<GUISpawnerCategory@> SortIntoCategories(array<GUISpawnerItem@> unsorted){
	array<GUISpawnerCategory@> sorted;

	for(uint i = 0; i < unsorted.size(); i++){

		int category_index = -1;
		for(uint j = 0; j < sorted.size(); j++){
			if (sorted[j].category_name == unsorted[i].category){
				category_index = j;
			}
		}

		if(category_index == -1){
			GUISpawnerCategory new_category(unsorted[i].category);
			new_category.AddItem(@unsorted[i]);
			sorted.insertLast(@new_category);
		}else{
			sorted[category_index].AddItem(@unsorted[i]);
		}
	}
	return sorted;
}

void Display(){
	if(show){
		ImGui_Begin("Spawner", show, ImGuiWindowFlags_NoScrollbar);
		ImGui_BeginChild(99, vec2(ImGui_GetWindowWidth(), top_bar_height), false, ImGuiWindowFlags_AlwaysUseWindowPadding | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);
		ImGui_Columns(3, false);
		if(ImGui_InputText("Search", ImGuiInputTextFlags_AutoSelectAll)){
			categories = SortIntoCategories(QuerySpawnerItems(ImGui_GetTextBuf()));
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

			for(uint i = 0; i < categories.size(); i++){
				AddCategory(categories[i]);
			}
			ImGui_Image(youdied_texture, vec2(ImGui_GetWindowWidth() - padding, ImGui_GetWindowWidth() / 4.75f - padding));
			ImGui_EndChildFrame();
		}
		ImGui_End();
	}
}

void AddCategory(GUISpawnerCategory@ category){
	if(category.spawner_items.size() < 1){
		return;
	}
	ImGui_PushStyleColor(ImGuiCol_Border, vec4(0.0f, 0.5f, 0.5f, 0.5f));
	ImGui_PushStyleColor(ImGuiCol_Header, vec4(1.0f, 0.5f, 0.0f, 0.5f));
	if(ImGui_TreeNodeEx(category.category_name, ImGuiTreeNodeFlags_CollapsingHeader | ImGuiTreeNodeFlags_DefaultOpen)){
		ImGui_Unindent(30.0f);
		ImGui_BeginChild(category.category_name, vec2(ImGui_GetWindowWidth(), icon_size), false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoInputs);
		float row_size = 0.0f;
		for(uint i = 0; i < category.spawner_items.size(); i++){
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
			AddItem(category.spawner_items[i]);
		}
		ImGui_EndChild();
		ImGui_Indent(30.0f);
		ImGui_TreePop();
	}
	ImGui_PopStyleColor();
}

void AddItem(GUISpawnerItem@ spawner_item){
	ImGui_PushStyleColor(ImGuiCol_ChildWindowBg, vec4(1.0f, 0.0f, 1.0f, 0.1f));
	ImGui_BeginChild(spawner_item.id + "button", vec2(icon_size), true, ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoScrollbar);

	ImGui_Text(spawner_item.title);

	if(currently_selected == spawner_item.title){
		ImGui_PushStyleColor(ImGuiCol_Button, vec4(1.0f, 0.0f, 1.0f, 0.5f));
	}
	else{
		ImGui_PushStyleColor(ImGuiCol_Button, vec4(0.0f));
	}

	ImGui_Indent((title_height / 2.0f) - (padding / 2.0f));
	if (ImGui_ImageButton(spawner_item.icon, vec2(icon_size - title_height,icon_size - title_height))){
		if(currently_selected == spawner_item.title){
			currently_selected = "";
			spawn = false;
		}else{
			currently_selected = spawner_item.title;
			load_item_path = spawner_item.path;
			spawn = true;
		}
	}
	ImGui_Unindent((title_height / 2.0f) - (padding / 2.0f));

	ImGui_PopStyleColor();
	ImGui_EndChild();
	ImGui_PopStyleColor();
}
