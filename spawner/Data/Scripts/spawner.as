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
bool paint = false;
bool paint_container_hover = false;
vec3 spawn_position;
bool rand_x = false;
bool rand_y = false;
bool rand_z = false;
float paint_max_distance = 1.0;
string currently_selected = "";
string load_item_path = "";
array<vec3> painted_objects;
array<vec3> painted_positions;
int placeholder_id = -1;
float paint_timer = 0.0;
float paint_timeout = 0.1;
float spawn_height_offset = 0.0;
bool open_palette = false;
bool steal_focus = false;

// Coloring options
vec4 background_color();
vec4 titlebar_color();
vec4 item_background();
vec4 item_hovered();
vec4 item_clicked();
vec4 text_color();

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
	bool has_thumbnail = false;

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

	void DrawItem(){
		if(currently_selected == path){
			ImGui_PushStyleColor(ImGuiCol_ChildBg, item_clicked);
		}
		else{
			ImGui_PushStyleColor(ImGuiCol_ChildBg, item_background);
		}

		ImGui_BeginChild(id + "button", vec2(icon_size), true, ImGuiWindowFlags_NoScrollWithMouse);
		ImGui_Indent((title_height / 2.0f) - (padding / 2.0f));
		ImGui_Text(title);
		ImGui_PushStyleColor(ImGuiCol_Button, vec4(0.0f));
		if(ImGui_ImageButton(icon, vec2(icon_size - title_height,icon_size - title_height))){
			if(currently_selected == path){
				ClearSpawnSettings();
			}else{
				currently_selected = path;
				SetSpawnSettings(path);
			}
		}
		ImGui_Unindent((title_height / 2.0f) - (padding / 2.0f));
		ImGui_PopStyleColor(2);

		ImGui_EndChild();

		if(!has_thumbnail && ImGui_IsItemVisible()){
			SetThumbnail();
			has_thumbnail = true;
		}
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
	LoadPalette();
}

void LoadPalette(bool use_defaults = false){
	JSON data;
	JSONValue root;
	bool retrieve_default_palette = false;

	SavedLevel@ saved_level = save_file.GetSavedLevel("spawner_data");
	string palette_data = saved_level.GetValue("spawner_palette");

	//Check if the saved json is parseble, available or just use the defaults.
	if(palette_data == "" || !data.parseString(palette_data) || use_defaults){
		if(!data.parseString(palette_data)){
			Log(warning, "Unable to parse the saved JSON in the palette!");
		}
		retrieve_default_palette = true;
	}else{
		Log(warning, "Saved palette JSON loaded correctly.");
	}

	//Check if the existing saved data has the relevant data.
	if(!retrieve_default_palette){
		root = data.getRoot();
		if(!root.isMember("Function Palette")){
			Log(warning, "Could not find Function Palette in JSON.");
			retrieve_default_palette = true;
		}else if(!root.isMember("UI Palette")){
			Log(warning, "Could not find UI Palette in JSON.");
			retrieve_default_palette = true;
		}
	}

	//Get the defaults values.
	if(retrieve_default_palette){
		Log(warning, "Loading the default palette.");
		if(!data.parseFile("Data/Scripts/spawner_default_palette.json")){
			Log(warning, "Error loading the default palette.");
			return;
		}
		root = data.getRoot();
	}else{
		Log(warning, "Using the palette from the saved JSON.");
	}

	JSONValue ui_palette = root["UI Palette"];

	JSONValue bg_color = ui_palette["Background Color"];
	background_color = vec4(bg_color[0].asFloat(), bg_color[1].asFloat(), bg_color[2].asFloat(), bg_color[3].asFloat());

	JSONValue tb_color = ui_palette["Titlebar Color"];
	titlebar_color = vec4(tb_color[0].asFloat(), tb_color[1].asFloat(), tb_color[2].asFloat(), tb_color[3].asFloat());

	JSONValue ib_color = ui_palette["Item Background"];
	item_background = vec4(ib_color[0].asFloat(), ib_color[1].asFloat(), ib_color[2].asFloat(), ib_color[3].asFloat());

	JSONValue ih_color = ui_palette["Item Hovered"];
	item_hovered = vec4(ih_color[0].asFloat(), ih_color[1].asFloat(), ih_color[2].asFloat(), ih_color[3].asFloat());

	JSONValue ic_color = ui_palette["Item Clicked"];
	item_clicked = vec4(ic_color[0].asFloat(), ic_color[1].asFloat(), ic_color[2].asFloat(), ic_color[3].asFloat());

	JSONValue t_color = ui_palette["Text Color"];
	text_color = vec4(t_color[0].asFloat(), t_color[1].asFloat(), t_color[2].asFloat(), t_color[3].asFloat());
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
		Log(warning, "Creating object " + load_item_path);
		int id = CreateObject(load_item_path, false);
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
	//If the query is empty then just return the whole database.
	if(query == ""){
		new_list = all_items;
	}else{
		//The query can be multiple words separated by spaces.
		array<string> split_query = query.split(" ");
		for(uint i = 0; i < all_items.size(); i++){
			string item_name = ToLowerCase(all_items[i].title);
			string category_name = ToLowerCase(all_items[i].category);
			bool found_result = true;

			for(uint j = 0; j < split_query.size(); j++){
				//Could not find part of query in the database.
				string query_part = ToLowerCase(split_query[j]);
				if(item_name.findFirst(query_part) == -1 && category_name.findFirst(query_part) == -1){
					found_result = false;
					break;
				}
			}
			//Only if all parts of the query are found then add the result.
			if(found_result){
				new_list.insertLast(all_items[i]);
			}
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

void DrawGUI(){
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

		ImGui_PushStyleColor(ImGuiCol_WindowBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_PopupBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgActive, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgCollapsed, background_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBg, background_color);
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

		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(550,450));
		ImGui_Begin("Spawner", show, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_MenuBar);
		ImGui_PopStyleVar(1);

		if(steal_focus){
			steal_focus = false;
			ImGui_SetNextWindowFocus();
		}

		if(open_palette){
			ImGui_OpenPopup("Configure Palette");
			open_palette = false;
		}

		DrawPalettePopup();

		if(ImGui_BeginMenuBar()){
			if(ImGui_Button("Load File")){
				string path = GetUserPickedReadPath("xml", "Data/Objects");
				if(path == ""){
					return;
				}
				SetSpawnSettings(path);
			}

			if(ImGui_BeginMenu("Settings")){
				if(ImGui_MenuItem("Configure Palette")){
					open_palette = true;
				}

				if(ImGui_DragInt("Icon Size", icon_size, 1.0, 75, 500, "%.0f")){

				}

				if(ImGui_DragFloat("Paint Distance", paint_max_distance, 0.01f, 0.0f, 100.0f, "%.1f")){

				}

				if(ImGui_Checkbox("Paint Random X Rotation", rand_x)){}
				if(ImGui_Checkbox("Paint Random Y Rotation", rand_y)){}
				if(ImGui_Checkbox("Paint Random Z Rotation", rand_z)){}

				if(ImGui_DragFloat("Height Offset", spawn_height_offset, 0.01, -100.0, 100.0, "%.1f")){

				}


				ImGui_EndMenu();
			}
			ImGui_EndMenuBar();
		}

		ImGui_BeginChild("FirstBar", vec2(ImGui_GetWindowWidth(), top_bar_height), false, ImGuiWindowFlags_AlwaysUseWindowPadding | ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoScrollbar);

		ImGui_SameLine();
		ImGui_AlignTextToFramePadding();
		ImGui_Text("Search : ");
		ImGui_SameLine();
		ImGui_PushItemWidth(ImGui_GetWindowWidth() - 175);
		if(ImGui_InputText("##Search", ImGuiInputTextFlags_AutoSelectAll)){
			categories = SortIntoCategories(QuerySpawnerItems(ImGui_GetTextBuf()));
		}
		ImGui_SameLine();
		if(ImGui_Checkbox("Paint", paint)){
			/* DeselectAll();
			ClearSpawnSettings(); */
		}

		ImGui_EndChild();

		ImGui_PushStyleColor(ImGuiCol_FrameBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
		if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth() - scrollbar_width, ImGui_GetWindowHeight() - (top_bar_height * 2.0 + padding * 3.0)))){
			for(uint i = 0; i < categories.size(); i++){
				AddCategory(categories[i]);
			}
			ImGui_EndChildFrame();
		}
		ImGui_End();
		ImGui_PopStyleColor(19);
	}
}

void DrawPalettePopup(){
	ImGui_SetNextWindowSize(vec2(700.0f, 450.0f), ImGuiSetCond_FirstUseEver);
	if(ImGui_BeginPopupModal("Configure Palette", ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse)){
		if(ImGui_Button("Reset to defaults")){
			LoadPalette(true);
			SavePalette();
		}
		ImGui_Separator();

		ImGui_BeginChild("Palette", vec2(-1, -1));
		ImGui_PushItemWidth(-1);
		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, 200.0);

		ImGui_Text("UI Colors");
		ImGui_NextColumn();
		ImGui_NextColumn();

		ImGui_Text("Background Color");
		ImGui_NextColumn();
		ImGui_PushItemWidth(-1);
		ImGui_ColorEdit4("##Background Color", background_color);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_Text("Titlebar Color");
		ImGui_NextColumn();
		ImGui_PushItemWidth(-1);
		ImGui_ColorEdit4("##Titlebar Color", titlebar_color);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_Text("Item Background");
		ImGui_NextColumn();
		ImGui_PushItemWidth(-1);
		ImGui_ColorEdit4("##Item Background", item_background);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_Text("Item Hovered");
		ImGui_NextColumn();
		ImGui_PushItemWidth(-1);
		ImGui_ColorEdit4("##Item Hovered", item_hovered);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_Text("Item Clicked");
		ImGui_NextColumn();
		ImGui_PushItemWidth(-1);
		ImGui_ColorEdit4("##Item Clicked", item_clicked);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_Text("Text Color");
		ImGui_NextColumn();
		ImGui_PushItemWidth(-1);
		ImGui_ColorEdit4("##Text Color", text_color);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_PopItemWidth();
		ImGui_EndChild();

		if((!ImGui_IsMouseHoveringAnyWindow() && ImGui_IsMouseClicked(0)) || ImGui_IsKeyPressed(ImGui_GetKeyIndex(ImGuiKey_Escape))){
			steal_focus = true;
			SavePalette();
			ImGui_CloseCurrentPopup();
		}

		ImGui_EndPopup();
	}
}

void SavePalette(){
	JSON data;
	JSONValue root;
	JSONValue ui_palette;

	JSONValue bg_color = JSONValue(JSONarrayValue);
	bg_color.append(background_color.x);
	bg_color.append(background_color.y);
	bg_color.append(background_color.z);
	bg_color.append(background_color.a);
	ui_palette["Background Color"] = bg_color;

	JSONValue tb_color = JSONValue(JSONarrayValue);
	tb_color.append(titlebar_color.x);
	tb_color.append(titlebar_color.y);
	tb_color.append(titlebar_color.z);
	tb_color.append(titlebar_color.a);
	ui_palette["Titlebar Color"] = tb_color;

	JSONValue ib_color = JSONValue(JSONarrayValue);
	ib_color.append(item_background.x);
	ib_color.append(item_background.y);
	ib_color.append(item_background.z);
	ib_color.append(item_background.a);
	ui_palette["Item Background"] = ib_color;

	JSONValue ih_color = JSONValue(JSONarrayValue);
	ih_color.append(item_hovered.x);
	ih_color.append(item_hovered.y);
	ih_color.append(item_hovered.z);
	ih_color.append(item_hovered.a);
	ui_palette["Item Hovered"] = ih_color;

	JSONValue ic_color = JSONValue(JSONarrayValue);
	ic_color.append(item_clicked.x);
	ic_color.append(item_clicked.y);
	ic_color.append(item_clicked.z);
	ic_color.append(item_clicked.a);
	ui_palette["Item Clicked"] = ic_color;

	JSONValue t_color = JSONValue(JSONarrayValue);
	t_color.append(text_color.x);
	t_color.append(text_color.y);
	t_color.append(text_color.z);
	t_color.append(text_color.a);
	ui_palette["Text Color"] = t_color;

	root["UI Palette"] = ui_palette;

	data.getRoot() = root;
	SavedLevel@ saved_level = save_file.GetSavedLevel("drika_data");
	saved_level.SetValue("drika_palette", data.writeString(false));
	save_file.WriteInPlace();
}

void AddCategory(GUISpawnerCategory@ category){
	if(category.spawner_items.size() < 1){
		return;
	}

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
			category.spawner_items[i].DrawItem();
		}
		ImGui_EndChild();
		ImGui_Indent(30.0f);
		ImGui_TreePop();
	}
}

void SetPlaceholderModel(){
	if(!FileExists(load_item_path)){
		Object@ placeholder_box = ReadObjectFromID(placeholder_id);
		PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(placeholder_box);
		placeholder_object.SetPreview("");
		return;
	}
	Log(warning, "Creating object " + load_item_path);
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
