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
bool paint = false;
bool paint_container_hover = false;
vec3 spawn_position;
bool rand_x = false;
bool rand_y = false;
bool rand_z = false;
float paint_max_distance = 1.0;
uint thumbnail_retrieve_index = 0;
string currently_selected = "";
string load_item_path = "";
array<vec3> painted_objects;
array<vec3> painted_positions;
int placeholder_id = -1;
float paint_timer = 0.0;
float paint_timeout = 0.1;
float spawn_height_offset = 0.0;

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
		if(spawner_item.GetThumbnail() == "" || !FileExists(spawner_item.GetThumbnail())){
			return;
		}else{
			icon = LoadTexture(spawner_item.GetThumbnail(), TextureLoadFlags_NoMipmap | TextureLoadFlags_NoReduce);
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
		spawner_items.insertLast(item);
	}
}

void Init(string str){
}

void GetAllSpawnerItems(){
	array<SpawnerItem> spawner_items = ModGetAllSpawnerItems();
	for(uint i = 0; i < spawner_items.size(); i++){
		TextureAssetRef icon_texture = default_texture;
		all_items.insertLast(GUISpawnerItem(spawner_items[i].GetCategory(), spawner_items[i].GetTitle(), spawner_items[i].GetPath(), i, icon_texture, spawner_items[i]));
	}
}

void Update(int paused){
	if(EditorModeActive()){
		UpdatePlaceholder();
		if(show && (spawn || paint && load_item_path != "")){
			if(spawn && GetInputPressed(0, "mouse0")){
				if(GetInputPressed(0, "mouse0")){
					SpawnObject(load_item_path);
					ClearSpawnSettings();
				}
			}else if(paint && paint_container_hover){
				if(ImGui_IsMouseDown(0)){
					paint_timer += time_step;
					//Drag spawning when painting.
					if(paint_timer > paint_timeout){
						if(CanPaint(spawn_position)){
							SpawnObject(load_item_path);
						}
					}
				}else if(paint_timer > 0.0){
					//Single click spawn when painting.
					if(CanPaint(spawn_position)){
						SpawnObject(load_item_path);
					}
					paint_timer = 0.0;
				}
			}
			if(GetInputDown(0, "pageup")){
				spawn_height_offset += time_step;
			}else if(GetInputDown(0, "pagedown")){
				spawn_height_offset -= time_step;
			}else if(GetInputDown(0, "q")){
				ClearSpawnSettings();
			}
		}
		if(GetInputPressed(0, "i")){
			show = !show;
			SetPlaceholderVisible(show);
		}
		if(show && !retrieved_item_list){
			GetAllSpawnerItems();
			categories = SortIntoCategories(QuerySpawnerItems(""));
			retrieved_item_list = true;
		}
	}else if(show){
		show = false;
	}
}

void ClearSpawnSettings(){
	load_item_path = "";
	currently_selected = "";
	spawn = false;
	SetPlaceholderVisible(false);
}

void SetSpawnSettings(string path){
	load_item_path = path;
	SetPlaceholderModel();
	spawn = true;
	SetPlaceholderVisible(true);
}

void UpdatePlaceholder(){
	if(placeholder_id == -1 || !ObjectExists(placeholder_id)){
		placeholder_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", true);
		Object@ obj = ReadObjectFromID(placeholder_id);
		obj.SetTint(vec3(1.0, 1.0, 1.0));
		PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
		placeholder_object.SetEditorDisplayName("SpawnPlaceholder");
		return;
	}else if(show && (spawn || paint && load_item_path != "")){
		spawn_position = col.GetRayCollision(camera.GetPos(), camera.GetPos() + (camera.GetMouseRay() * 500.0f));
		Object@ placeholder_object = ReadObjectFromID(placeholder_id);
		placeholder_object.SetTranslation(spawn_position + vec3(0, spawn_height_offset, 0));
	}
}

void SetPlaceholderVisible(bool visible){
	Object@ placeholder_object = ReadObjectFromID(placeholder_id);
	placeholder_object.SetTranslation(vec3(0,-1000,0));
	placeholder_object.SetEnabled(visible);
}

bool CanPaint(vec3 position){
	for(uint i = 0; i < painted_positions.size(); i++){
		if(distance(painted_positions[i], position) < paint_max_distance){
			return false;
		}
	}
	return true;
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	while(token_iter.FindNextToken(msg)){
		string token = token_iter.GetToken(msg);
		if(token == "notify_deleted"){
			token_iter.FindNextToken(msg);
			int id = atoi(token_iter.GetToken(msg));
			/* Log(info, "deleting " + painted_objects.size() + " " + painted_positions.size()); */
			for(uint i = 0; i < painted_objects.size(); i++){
				if(painted_objects[i] == id){
					painted_objects.removeAt(i);
					painted_positions.removeAt(i);
					break;
				}
			}
		}
	}
}

void SpawnObject(string load_item_path){
	if(FileExists(load_item_path)){
		int id = CreateObject(load_item_path, false);
		/* Log(info, "Creating object " + load_item_path); */
		Object@ obj = ReadObjectFromID(id);
		if(paint){
			quaternion new_rotation = quaternion(vec4(rand_x?1.0:0.0f,rand_y?1.0:0.0f,rand_z?1.0:0.0f, RangedRandomFloat(-1, 1)));
			obj.SetRotation(new_rotation);
		}
		obj.SetTranslation(spawn_position + vec3(0, spawn_height_offset, 0));
		obj.SetCopyable(true);
		obj.SetSelectable(true);
		obj.SetTranslatable(true);
		obj.SetScalable(true);
		obj.SetRotatable(true);
		obj.SetDeletable(true);
		DeselectAll();
		obj.SetSelected(true);
		painted_positions.insertLast(spawn_position);
		painted_objects.insertLast(id);
	}else{
		DisplayError("Error", "This xml file does not exist: " + load_item_path);
	}
}

array<GUISpawnerItem@> QuerySpawnerItems(string query){
	array<GUISpawnerItem@> new_list;
	new_list.resize(0);
	for(uint i = 0; i < all_items.size(); i++){
		if(ToLowerCase(all_items[i].title).findFirst(ToLowerCase(query)) != -1 || ToLowerCase(all_items[i].category).findFirst(ToLowerCase(query)) != -1){
			new_list.insertLast(all_items[i]);
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
			new_category.AddItem(unsorted[i]);
			sorted.insertLast(new_category);
		}else{
			sorted[category_index].AddItem(unsorted[i]);
		}
	}
	return sorted;
}

void Display(){
	if(show){
		if(paint && currently_selected != ""){
			ImGui_PushStyleColor(ImGuiCol_WindowBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
			ImGui_Begin("PaintContainer", show, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoBringToFrontOnFocus);
			ImGui_PopStyleColor(1);
			if(ImGui_IsWindowHovered()){
				paint_container_hover = true;
			}else{
				paint_container_hover = false;
			}
			ImGui_SetWindowPos("PaintContainer", vec2(0,0));
			ImGui_SetWindowSize("PaintContainer", vec2(GetScreenWidth(), GetScreenHeight()));
			ImGui_End();
		}

		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(550,450));
		if(!retrieved_thumbnails){
			ImGui_Begin("Spawner..." + "Loading icon " + thumbnail_retrieve_index + "/" + all_items.size(), show, ImGuiWindowFlags_NoScrollbar);
		}else{
			ImGui_Begin("Spawner", show, ImGuiWindowFlags_NoScrollbar);
		}
		ImGui_PopStyleVar(1);

		ImGui_BeginChild("FirstBar", vec2(ImGui_GetWindowWidth() - 30, top_bar_height), false, ImGuiWindowFlags_AlwaysUseWindowPadding | ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoScrollbar);

		if(ImGui_Button("Load Item...")){
			string path = GetUserPickedReadPath("xml", "Data/Objects");
			SetSpawnSettings(path);
		}

		ImGui_SameLine();
		ImGui_PushItemWidth(ImGui_GetWindowWidth() - 300);
		if(ImGui_InputText("Search", ImGuiInputTextFlags_AutoSelectAll)){
			categories = SortIntoCategories(QuerySpawnerItems(ImGui_GetTextBuf()));
		}

		ImGui_SameLine();
		ImGui_PushItemWidth(50.0);
		ImGui_DragInt("Icon Size", icon_size, 1.0f, 75, 500, "%.0f");

		ImGui_EndChild();

		ImGui_BeginChild("SecondBar", vec2(ImGui_GetWindowWidth() - 30, top_bar_height), false, ImGuiWindowFlags_AlwaysUseWindowPadding | ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoScrollbar);

		if(ImGui_Checkbox("Paint", paint)){
			/* DeselectAll();
			ClearSpawnSettings(); */
		}

		ImGui_SameLine();
		ImGui_PushItemWidth(50.0);
		ImGui_DragFloat("Distance", paint_max_distance, 0.01, 0.0, 100.0, "%.1f");
		ImGui_PopItemWidth();

		ImGui_SameLine();
		ImGui_TextWrapped("Random Rotation");
		ImGui_SameLine();
		ImGui_Checkbox("x", rand_x);
		ImGui_SameLine();
		ImGui_Checkbox("y", rand_y);
		ImGui_SameLine();
		ImGui_Checkbox("z", rand_z);
		ImGui_SameLine();
		ImGui_PushItemWidth(50.0);
		ImGui_DragFloat("Height Offset", spawn_height_offset, 0.01, -100.0, 100.0, "%.1f");
		ImGui_PopItemWidth();

		ImGui_EndChild();

		ImGui_PushStyleColor(ImGuiCol_FrameBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
		if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth() - scrollbar_width, ImGui_GetWindowHeight() - (top_bar_height + padding * 2.0) * 2.0))){
			ImGui_PopStyleColor(2);

			for(uint i = 0; i < categories.size(); i++){
				AddCategory(categories[i]);
			}
			ImGui_EndChildFrame();
		}
		ImGui_End();

		if(show && retrieved_item_list && !retrieved_thumbnails){
			while(true && !retrieved_thumbnails){
				GetNextThumbnail();
				if(thumbnail_retrieve_index % 50 == 0){
					break;
				}
			}
		}
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
		ImGui_BeginChild(category.category_name, vec2(ImGui_GetWindowWidth(), icon_size), false, ImGuiWindowFlags_NoScrollWithMouse);
		float row_size = 0.0f;
		for(uint i = 0; i < category.spawner_items.size(); i++){
			row_size += icon_size + padding;
			if(row_size > ImGui_GetWindowWidth()){
				row_size = icon_size + padding;
				ImGui_EndChild();
				ImGui_BeginChild("child " + i, vec2(ImGui_GetWindowWidth(), icon_size), false, ImGuiWindowFlags_NoScrollWithMouse);
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
	ImGui_BeginChild(spawner_item.id + "button", vec2(icon_size), true, ImGuiWindowFlags_NoScrollWithMouse);
	ImGui_BulletText(spawner_item.title);

	if(currently_selected == spawner_item.path){
		ImGui_PushStyleColor(ImGuiCol_Button, vec4(1.0f, 0.0f, 1.0f, 0.5f));
	}
	else{
		ImGui_PushStyleColor(ImGuiCol_Button, vec4(0.0f));
	}

	ImGui_Indent((title_height / 2.0f) - (padding / 2.0f));
	if (ImGui_ImageButton(spawner_item.icon, vec2(icon_size - title_height,icon_size - title_height))){
		if(currently_selected == spawner_item.path){
			ClearSpawnSettings();
		}else{
			currently_selected = spawner_item.path;
			SetSpawnSettings(spawner_item.path);
		}
	}
	ImGui_Unindent((title_height / 2.0f) - (padding / 2.0f));

	ImGui_PopStyleColor();
	ImGui_EndChild();
}

void SetPlaceholderModel(){
	if(!FileExists(load_item_path)){
		Object@ placeholder_box = ReadObjectFromID(placeholder_id);
		PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholder_box);
		placeholder_object.SetPreview("");
		return;
	}
	int id = CreateObject(load_item_path);
	Object@ obj = ReadObjectFromID(id);
	Object@ placeholder_box = ReadObjectFromID(placeholder_id);
	PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholder_box);
	if(obj.GetType() == _env_object){
		placeholder_object.SetPreview(load_item_path);
	}else{
		placeholder_object.SetPreview("");
	}
	QueueDeleteObjectID(id);
}

/* void Menu(){
	ImGui_Checkbox("Spawner", show);
} */
