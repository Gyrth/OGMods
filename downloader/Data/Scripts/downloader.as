string log_data = "";
uint16 api_port = 80;
uint main_socket = SOCKET_ID_INVALID;
bool show = true;
bool show_notification = false;
bool show_header = false;
float notification_slide = 0.0;
float notification_timer = 5.0;
string notification_text = "";
array<string> notification_queue;
tabs tab = download;
array<ModData@> mods;
array<ModData@> search_results;
string search_string = "";

bool post_init_done = false;
float progress_interval_timer = 0.0;
bool downloading = false;
string progress_text = "";
int selected_mod = 0;
int new_selected_mod = 0;

const string code_404 = "HTTP/1.1 404 ERROR ";
const string code_200 = "HTTP/1.1 200 OK\r";

array<Download@> download_queue;
Download@ current_download;
TextureAssetRef image = LoadTexture("Data/UI/spawner/thumbs/Hotspot/empty.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
TextureAssetRef star = LoadTexture("Data/UI/star_filled.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);
TextureAssetRef default_thumbnail = LoadTexture("Data/Textures/ui/menus/main/icon-x.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

// Coloring options
vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);
vec4 background_color(0.25, 0.25, 0.25, 1.0);
vec4 titlebar_color(0.15, 0.15, 0.15, 0.98);
vec4 item_hovered(0.2, 0.2, 0.2, 0.98);
vec4 item_clicked(0.1, 0.1, 0.1, 0.98);
vec4 text_color(0.7, 0.7, 0.7, 1.0);

enum tabs 	{
				download = 0,
				logger = 1
			};

enum download_types	{
						file = 0,
						directory = 1,
						mod_list = 2,
						thumbnail = 3
					};

class ModData{
	string name = "";
	string id = "";
	string version = "";
	string remote_version = "";
	string author = "";
	string remote_thumbnail_path = "";
	string local_thumbnail_path = "";
	TextureAssetRef thumbnail;
	string description = "";
	bool is_installed = false;
	bool is_enabled = false;
	bool has_mod_id = false;
	bool can_activate = false;
	bool is_remote_mod = false;
	bool is_local_mod = false;
	ModID mod_id;
	string error;

	ModData(string name, string id, string version, string author, string thumbnail_path, string description, bool is_remote_mod = false){
		this.name = name;
		this.id = id;
		this.version = version;
		this.author = author;
		this.description = description;
		this.is_remote_mod = is_remote_mod;

		if(is_remote_mod){
			this.remote_thumbnail_path = thumbnail_path;
		}else{
			local_thumbnail_path = thumbnail_path;
		}
		ReloadThumbnail();

		array<ModID>all_mods = GetModSids();
		for(uint i = 0; i < all_mods.size(); i++){
			if(ModGetID(all_mods[i]) == id){
				mod_id = all_mods[i];
				has_mod_id = true;
				break;
			}
		}
		UpdateStatus();
	}

	void UpdateStatus(){
		if(has_mod_id){
			is_installed = true;
			if(ModIsActive(mod_id)){
				is_enabled = true;
			}else{
				is_enabled = false;
			}
			if(ModCanActivate(mod_id)){
				can_activate = true;
			}else{
				can_activate = false;
			}
			error = ModGetValidityString(mod_id);
		}else{
			is_installed = false;
		}
	}

	void ReloadThumbnail(){
		if(is_remote_mod){
			array<string> split_path = remote_thumbnail_path.split("/");
			local_thumbnail_path = "Data/Downloads/Thumbnails/" + split_path[split_path.size() - 1];

			if(!FileExists(local_thumbnail_path)){
				QueueDownload(remote_thumbnail_path, this);
			}
		}

		if(FileExists(local_thumbnail_path)){
			thumbnail = LoadTexture(local_thumbnail_path, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoReduce);
		}else{
			thumbnail = default_thumbnail;
		}
	}
}

class Download{
	array<uint8> raw_data;
	string full_address;
	string file_path;
	string file_name;
	string file_extention;
	string server_address;
	bool has_header = false;
	bool error = false;
	string error_code = "";
	int file_size;
	int download_progress = 0;
	int packet_size = 0;
	float download_timer = 0.0;
	download_types download_type;
	ModData@ target;

	Download(string full_address, ModData@ target){
		@this.target = @target;
		this.full_address = full_address;

		array<string> split_address = full_address.split("/");
		//If the name ends with / then it's a subdirectory.
		if(@target != null){
			download_type = thumbnail;
		}else if(full_address.substr(full_address.length() -1, 1) == "/"){
			download_type = directory;
		}else if(split_address[split_address.length() -1] == "mod_list.json"){
			download_type = mod_list;
		}else{
			download_type = file;
		}
	}
}

class LabelData{
	string text;
	vec2 position;
	vec3 color;
	vec4 background_color;

	LabelData(string text, vec2 position, vec3 color, vec4 background_color){
		this.text = text;
		this.position = position;
		this.color = color;
		this.background_color = background_color;
	}
}

void Update(int paused){
	if(!post_init_done){
		PostInit();
		post_init_done = true;
	}
	if(downloading){
		progress_interval_timer += time_step;
		current_download.download_timer += time_step;

		if(progress_interval_timer > 0.2){
			/* Log(warning, "Progress " + download_progress); */

			progress_interval_timer = 0.0;
			UpdateProgressBar();
		}
	}else if(download_queue.size() > 0){
		@current_download = @download_queue[0];
		StartDownload();
	}
	if(new_selected_mod != selected_mod){
		selected_mod = new_selected_mod;
	}
	UpdateNotification();
}

void UpdateNotification(){
	//Still showing a notification.
	if(notification_timer < (notification_queue.size() > 0?1.0:5.0)){
		notification_timer += time_step;
		if(notification_slide < 325.0f){
			notification_slide += time_step * 1000.0;
		}
	}else{
		//Done showing notification.
		if(notification_queue.size() > 0){
			notification_slide = 0.0;
			show_notification = true;
			notification_timer = 0.0;
			notification_text = notification_queue[0];
			notification_queue.removeAt(0);
		}else if(show_notification){
			Log(warning, "Stop showing!");
			show_notification = false;
		}
	}
}

void ShowNotification(string message){
	Log(warning, message);
	notification_queue.insertLast(message);
}

void UpdateProgressBar(){
	string size;

	if(current_download.download_progress > 10000000){
		size = (current_download.download_progress / 1024.0 / 1024.0) + " megabytes";
	}else if(current_download.download_progress > 1024){
		size = (current_download.download_progress / 1024.0) + " kilobytes";
	}else{
		size = current_download.download_progress + " bytes";
	}

	string percentage = (current_download.download_progress * 100 / max(current_download.file_size, 1)) + "% - ";
	string speed = ((current_download.download_progress / max(current_download.download_timer, 0.001)) / 1024.0) + " kb/s. ";

	progress_text = "Download : " + size + " " + percentage + speed + "\nLast packet size : " + current_download.packet_size + " bytes.";
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	while(token_iter.FindNextToken(msg)){
		string token = token_iter.GetToken(msg);
		if(token == "notify_deleted"){
		}
	}
}

void DrawGUI(){
	if(show || show_notification){
		ImGui_PushStyleColor(ImGuiCol_WindowBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_PopupBg, background_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBgActive, titlebar_color);
		ImGui_PushStyleColor(ImGuiCol_TitleBg, item_hovered);
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
	}

	if(show){
		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 300));

		ImGui_SetNextWindowSize(vec2(600.0f, 400.0f), ImGuiSetCond_FirstUseEver);
		ImGui_SetNextWindowPos(vec2(100.0f, 100.0f), ImGuiSetCond_FirstUseEver);
		ImGui_Begin("Downloader " + "###Downloader", show, ImGuiWindowFlags_MenuBar | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);
		ImGui_PopStyleVar(1);

		/* ImGui_BeginChild("Child", vec2(200, 200), true, ImGuiWindowFlags_NoScrollbar);
		ImGui_Image(default_thumbnail, vec2(500,500));
		ImGui_EndChild(); */

		if(ImGui_BeginMenuBar()){
			if(ImGui_BeginMenu("Actions")){
				if(ImGui_MenuItem("Disable All Mods")){
					for(uint i = 0; i < mods.size(); i++){
						ModActivation(mods[i].mod_id, false);
						mods[i].UpdateStatus();
					}
				}
				if(ImGui_MenuItem("Enable All Mods")){
					for(uint i = 0; i < mods.size(); i++){
						ModActivation(mods[i].mod_id, true);
						mods[i].UpdateStatus();
					}
				}
				ImGui_EndMenu();
			}
			ImGui_EndMenuBar();
		}

		//Create the tabs at the top.
		vec2 tab_size = vec2(ImGui_GetWindowWidth() / 2.0 - 8.0, 20.0);

		ImGui_PushStyleColor(ImGuiCol_Header, vec4(0));
		ImGui_PushStyleColor(ImGuiCol_HeaderHovered, vec4(0));
		ImGui_PushStyleColor(ImGuiCol_HeaderActive, vec4(0));

		vec2 starting_position = ImGui_GetCursorScreenPos();

		ImDrawList_AddRectFilled(starting_position, starting_position + tab_size, ImGui_GetColorU32(tab == download?titlebar_color:item_hovered), 10.0f, ImDrawCornerFlags_Top);
		if(ImGui_Selectable("###Downloads", (tab == download), 0, tab_size) && tab != download){
			tab = download;
		}
		vec2 download_label_center_position = starting_position + vec2(tab_size.x / 2.0f, tab_size.y / 2.0f) - ImGui_CalcTextSize("Downloads") / 2.0f;
		ImDrawList_AddText(download_label_center_position, ImGui_GetColorU32(text_color), "Downloads");
		ImGui_SameLine();

		starting_position += vec2(tab_size.x, 0.0f);
		ImDrawList_AddRectFilled(starting_position, starting_position + tab_size, ImGui_GetColorU32(tab == logger?titlebar_color:item_hovered), 10.0f, ImDrawCornerFlags_Top);
		if(ImGui_Selectable("###Log", (tab == logger), 0, tab_size) && tab != logger){
			tab = logger;
		}
		vec2 log_label_center_position = starting_position + vec2(tab_size.x / 2.0f, tab_size.y / 2.0f) - ImGui_CalcTextSize("Log") / 2.0f;
		ImDrawList_AddText(log_label_center_position, ImGui_GetColorU32(text_color), "Log");

		ImGui_PopStyleColor(3);

		//Create the main window in which everything is shown.
		ImGui_Spacing();
		ImGui_BeginChild("MainWindow", vec2(-1.0, -1.0f), false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);

		float extra_label_width = 5.0f;
		vec2 p;
		vec2 size;

		ImGui_Spacing();

		array<ModData@> @target_list;

		if(search_string != ""){
			@target_list = @search_results;
		}else{
			@target_list = @mods;
		}

		if(tab == download){
			//Add the searchbar.
			ImGui_SetNextWindowPos(ImGui_GetCursorScreenPos() + vec2(ImGui_GetWindowWidth() / 8.0, 0.0));
			ImGui_BeginChild("Searchbar", vec2(ImGui_GetWindowWidth() / 4.0, 25.0f), false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);

			ImGui_PushItemWidth(50);
			ImGui_LabelText("###Search:", "Search:");
			ImGui_SameLine();
			ImGui_PushItemWidth(-1);
			ImGui_SetTextBuf(search_string);
			if(ImGui_InputText("##Search:", search_string, 64, ImGuiInputTextFlags_AutoSelectAll)){
				SearchMods(search_string);
			}

			if(search_string != ""){
				ImGui_SameLine();
				vec2 empty_button_start = ImGui_GetCursorScreenPos();
				empty_button_start.x -= 28.0;

				ImGui_SetNextWindowPos(empty_button_start);
				ImGui_BeginChild("EmptyButton", vec2(20.0, 20.0), false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);

				if(ImGui_InvisibleButton("EmptyButton", vec2(20.0, 20.0))){
					search_string = "";
				}
				ImDrawList_AddRectFilled(empty_button_start + vec2(2.0, 2.0), empty_button_start + vec2(18.0, 18.0), ImGui_GetColorU32(item_hovered), ImDrawCornerFlags_All);
				ImDrawList_AddText(empty_button_start + vec2(7.0, 3.0), ImGui_GetColorU32(text_color), "x");

				ImGui_EndChild();
			}

			ImGui_EndChild();

			ImGui_Columns(2, false);
			array<LabelData@> mod_list_labels;

			p = ImGui_GetCursorScreenPos() - vec2(0.0, 0.0);

			ImGui_BeginChild("ModList", vec2(ImGui_GetWindowWidth() / 2.0 - 13.0, -1.0), true);
			size = ImGui_GetWindowSize() + vec2(0.0, 0.0);

			vec2 mod_button_size = vec2(-1.0, 125.0f);

			for(uint i = 0; i < target_list.size(); i++){

				vec2 name_title_pos;
				ImGui_Spacing();
				if(selected_mod == int(i)){
					ImGui_PushStyleColor(ImGuiCol_ChildWindowBg, item_hovered);
				}

				ImGui_BeginChild(target_list[i].id, mod_button_size, true, ImGuiWindowFlags_NoScrollWithMouse);
				if(selected_mod != int(i) && ImGui_IsMouseHoveringWindow()){
					if(ImGui_IsMouseClicked(0)){
						new_selected_mod = int(i);
					}
				}

				size.x = ImGui_GetWindowWidth();
				p.x = ImGui_GetWindowPos().x;
				name_title_pos = ImGui_GetCursorScreenPos() + vec2(20.0, -15.0);

				if(selected_mod == int(i)){
					ImGui_PopStyleColor();
				}
				ImGui_Spacing();
				ImGui_Spacing();

				ImGui_SameLine();

				ImGui_Columns(2, false);

				ImGui_SetColumnWidth(0, 165);

				ImGui_Image(target_list[i].thumbnail, vec2(150, 100));
				ImGui_NextColumn();
				ImGui_TextWrapped(target_list[i].description);

				ImGui_EndChild();
				vec3 text_color = vec3(1, 1, 1);
				if(target_list[i].is_enabled){
					text_color = vec3(0.65, 1, 0.65);
				}else if(!target_list[i].can_activate){
					text_color = vec3(1, 0.65, 0.65);
				}

				mod_list_labels.insertLast(LabelData(target_list[i].name + " - " + target_list[i].author, name_title_pos, text_color, background_color));
			}

			ImGui_EndChild();

			ImGui_SetNextWindowPos(p);
			ImGui_BeginChild("ModListLabels", size, false, ImGuiWindowFlags_NoInputs | ImGuiWindowFlags_NoScrollbar);

			for(uint i = 0; i < mod_list_labels.size(); i++){
				vec2 text_size = ImGui_CalcTextSize(mod_list_labels[i].text);
				text_size.y /= 1.7;
				ImDrawList_AddRectFilled(mod_list_labels[i].position - vec2(extra_label_width, 0.0), mod_list_labels[i].position + text_size + vec2(extra_label_width, 0.0), ImGui_GetColorU32(mod_list_labels[i].background_color));
				ImDrawList_AddText(mod_list_labels[i].position, ImGui_GetColorU32(mod_list_labels[i].color), mod_list_labels[i].text);
			}

			ImGui_EndChild();

			ImGui_NextColumn();

			array<LabelData@> inspector_labels;
			ImGui_BeginChild("ModInspector", vec2(-1.0, -1.0), true, ImGuiWindowFlags_AlwaysUseWindowPadding);

			p = ImGui_GetCursorScreenPos() - vec2(8.0, 20.0);
			size = ImGui_GetWindowSize() + vec2(0.0, 12.0);

			inspector_labels.insertLast(LabelData("ModInspector", ImGui_GetWindowPos() + vec2(20.0, -7.0), vec3(1, 1, 1), background_color));

			if(target_list.size() > 0){
				float section_height = ImGui_GetWindowHeight() - 10.0;

				ImGui_BeginChild("Thumbnail", vec2(-1.0, section_height / 3.0), false, ImGuiWindowFlags_NoScrollWithMouse);
				float image_height = section_height / 3.0 - 10.0f;
				ImGui_Indent(ImGui_GetWindowWidth() / 2.0f - image_height);
				ImGui_Image(target_list[selected_mod].thumbnail, vec2(image_height * 2.0f, image_height));
				ImGui_EndChild();

				ImGui_BeginChild("Install", vec2(-1.0, target_list[selected_mod].can_activate?40.0:80.0), true);
				inspector_labels.insertLast(LabelData(target_list[selected_mod].name, ImGui_GetWindowPos() + vec2(20.0, -7.0), vec3(1, 1, 1), background_color));

				ImGui_Spacing();

				if(!target_list[selected_mod].is_installed){
					ImGui_Button("Install");
				}else{
					if(target_list[selected_mod].is_enabled){
						if(ImGui_Button("Disable")){
							bool succes = ModActivation(target_list[selected_mod].mod_id, false);
							target_list[selected_mod].UpdateStatus();
						}
					}else{
						if(!target_list[selected_mod].can_activate){
							ImGui_PushStyleColor(ImGuiCol_Text, vec4(1.0, 0.65, 0.65, 1.0));
							ImGui_TextWrapped(target_list[selected_mod].error);
							ImGui_PopStyleColor();
						}else{
							if(ImGui_Button("Enable")){
								ModActivation(target_list[selected_mod].mod_id, true);
								target_list[selected_mod].UpdateStatus();
								target_list[selected_mod].ReloadThumbnail();
							}
						}
					}
				}
				ImGui_EndChild();
				ImGui_Spacing();

				ImGui_BeginChild("Details", vec2(-1, 70.0), true, ImGuiWindowFlags_NoScrollWithMouse);
				inspector_labels.insertLast(LabelData("Details", ImGui_GetWindowPos() + vec2(20.0, -7.0), vec3(1, 1, 1), background_color));

				ImGui_Columns(2, false);

				ImGui_Text("Author : " + target_list[selected_mod].author);
				ImGui_Text("ID : " + target_list[selected_mod].id);
				ImGui_Text("Version : " + target_list[selected_mod].version);

				ImGui_NextColumn();

				ImGui_Text("Status : " + "Not installed");
				ImGui_Text("Downloads : " + "12");

				ImGui_EndChild();
				ImGui_Spacing();

				ImGui_BeginChild("Description", vec2(-1.0, -1.0), true, ImGuiWindowFlags_NoScrollWithMouse);
				inspector_labels.insertLast(LabelData("Description", ImGui_GetWindowPos() + vec2(20.0, -7.0), vec3(1, 1, 1), background_color));

				ImGui_TextWrapped(target_list[selected_mod].description);
				ImGui_EndChild();
			}

			ImGui_EndChild();

			ImGui_SetNextWindowPos(p);
			ImGui_BeginChild("InspectorLabels", size, false, ImGuiWindowFlags_NoInputs | ImGuiWindowFlags_AlwaysUseWindowPadding);

			for(uint i = 0; i < inspector_labels.size(); i++){
				ImDrawList_AddRectFilled(inspector_labels[i].position - vec2(extra_label_width, 0.0), inspector_labels[i].position + ImGui_CalcTextSize(inspector_labels[i].text) + vec2(extra_label_width, 0.0), ImGui_GetColorU32(inspector_labels[i].background_color));
				ImDrawList_AddText(inspector_labels[i].position, ImGui_GetColorU32(inspector_labels[i].color), inspector_labels[i].text);
			}
			ImGui_EndChild();

		}else if(tab == logger){
			ImGui_SetTextBuf(log_data);
			ImGui_InputTextMultiline("Log", vec2(-1.0, ImGui_GetWindowHeight() - 120.0), ImGuiInputTextFlags_ReadOnly);
			ImGui_Text(progress_text);
		}
		ImGui_EndChild();

		ImGui_End();
	}

	if(show_notification){
		ImGui_SetNextWindowSize(vec2(300.0f, 125.0f), ImGuiSetCond_Always);
		ImGui_SetNextWindowPos(vec2(GetScreenWidth() - notification_slide, GetScreenHeight() - 150.0f), ImGuiSetCond_Always);

		ImGui_PushStyleVar(ImGuiStyleVar_Alpha, 0.5f);
		ImGui_Begin("Notification " + "###Notification", show_notification, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove);
		ImGui_Image(star, vec2(100, 100));
		ImGui_SameLine();
		ImGui_TextWrapped(notification_text);
		ImGui_End();
		ImGui_PopStyleVar();
	}

	if(show || show_notification){
		ImGui_PopStyleColor(17);
	}
}

void SearchMods(string query){
	search_results.resize(0);
	new_selected_mod = 0;
	string query_lower = ToLowerCase(query);

	for(uint i = 0; i < mods.size(); i++){
		if(ToLowerCase(mods[i].name).findFirst(query_lower) != -1 || ToLowerCase(mods[i].id).findFirst(query_lower) != -1 || ToLowerCase(mods[i].author).findFirst(query_lower) != -1){
			search_results.insertLast(mods[i]);
		}
	}
}

void Init(string level_name){
}

void PostInit(){
	ReadLocalMods();
	QueueDownload("107.173.129.154/downloader/mod_list.json");
}

void ReadLocalMods(){
	array<ModID> all_mods = GetModSids();

	for(uint i = 0; i < all_mods.size(); i++){
		ModData mod(ModGetName(all_mods[i]),ModGetID(all_mods[i]), ModGetVersion(all_mods[i]), ModGetAuthor(all_mods[i]), ModGetThumbnail(all_mods[i]), ModGetDescription(all_mods[i]));
		mods.insertLast(@mod);
	}
}

void QueueDownload(string full_address, ModData@ target = null){
	download_queue.insertLast(Download(full_address, target));
}

void StartDownload(){
	array<string> split_address = current_download.full_address.split("/");
	current_download.server_address = split_address[0];

	TCPLog("Downloading file : " + current_download.full_address);

	for(uint i = 1; i < split_address.size(); i++){
		current_download.file_path += "/" + split_address[i];
	}

	array<string> split_file_name = split_address[split_address.size() - 1].split(".");
	current_download.file_name = split_file_name[0];
	if(split_file_name.size() > 1){
		current_download.file_extention = split_file_name[1];
	}

	SendRequest(current_download.server_address, "GET " + current_download.file_path + " HTTP/1.1\r\nHost: " + current_download.server_address + "\r\n\r\n");
}

void SendRequest(string address, string request){
	current_download.has_header = false;

	if( main_socket == SOCKET_ID_INVALID ) {
		main_socket = CreateSocketTCP(address, api_port);
        if( main_socket != SOCKET_ID_INVALID ) {
            Log( info, "Connected " + main_socket );
			array<uint8> message = toByteArray(request);
			if( IsValidSocketTCP(main_socket) ){
				downloading = true;
		        SocketTCPSend(main_socket, message);
			}
        } else {
            Log( warning, "Unable to connect" );
        }
    }
}

void IncomingTCPData(uint socket, array<uint8>@ data) {
	for(uint i = 0; i < data.size(); i++){
		current_download.raw_data.insertLast(data[i]);
	}

	if(!current_download.has_header){
		//Check if the whole head has been received.
		for(uint i = 0; i < current_download.raw_data.size() - 2; i++){
			if(current_download.raw_data[i] == 13 && current_download.raw_data[i + 1] == 10 && current_download.raw_data[i + 2] == 13){
				current_download.has_header = true;
				ReadHeader(i + 4);
				break;
			}
		}
	}else if(current_download.error){
		TCPLog("Error downloading : " + current_download.error_code);
		TCPLog("-----------------------------------------------");
		ClearDownload();
	}else if(current_download.has_header){
		current_download.download_progress += data.size();
		current_download.packet_size = data.size();

		if(current_download.download_progress >= current_download.file_size){
			//Done downloading!
			TCPLog("Download size : " + current_download.download_progress + " bytes.");
			TCPLog("Download time : " + current_download.download_timer + " seconds.");
			TCPLog("Download speed : " + (current_download.file_size / current_download.download_timer) / 1024.0 + " kb/s.");
			TCPLog("-----------------------------------------------");
			UpdateProgressBar();

			if(current_download.download_type == thumbnail){
				ShowNotification("Thumbnail download done : \n" + current_download.full_address);
				WriteDownloadedFile("Data/Downloads/Thumbnails/");
				current_download.target.ReloadThumbnail();
			}else if(current_download.download_type == file){
				ShowNotification("Download done : \n" + current_download.full_address);
				WriteDownloadedFile("Data/Downloads/");
			}else if(current_download.download_type == directory){
				DownloadFilesInDirectory();
			}else if(current_download.download_type == mod_list){
				ReadModList();
			}
			ClearDownload();
		}
	}
}

void ReadModList(){
	JSON json;
	json.parseString(GetString(current_download.raw_data));

	JSONValue root = json.getRoot();
	array<string> array_members = root.getMemberNames();

	for(uint i = 0; i < array_members.size(); i++){
		JSONValue mod_data = root[array_members[i]];
		bool already_local = false;

		for(uint j = 0; j < mods.size(); j++){
			//The remote mod is already loaded as a local mod.
			if(mods[j].id == mod_data["ID"].asString()){
				mods[j].is_remote_mod = true;
				mods[j].remote_version = mod_data["Version"].asString();
				mods[j].remote_thumbnail_path = mod_data["Thumbnail"].asString();
				already_local = true;
				mods[j].ReloadThumbnail();

				break;
			}
		}

		if(already_local){
			continue;
		}

		ModData mod(mod_data["Name"].asString(), mod_data["ID"].asString(), mod_data["Version"].asString(), mod_data["Author"].asString(), mod_data["Thumbnail"].asString(), mod_data["Description"].asString(), true);
		mods.insertLast(@mod);
	}
}

void ClearDownload(){
	downloading = false;
	download_queue.removeAt(0);
	DestroySocketTCP(main_socket);
	main_socket = SOCKET_ID_INVALID;
}

void DownloadFilesInDirectory(){
	array<string> result = ExtractStringBetween(GetString(current_download.raw_data), "<tr>", "</tr>");

	TCPLog("Directory list : ");
	int counter = 0;
	//Skip the first 3 lines since those are headers.
	for(uint i = 3; i < result.size(); i++){
		array<string> file_name = ExtractStringBetween(result[i], "<a href=\"", "\">");
		if(file_name.size() > 0){
			TCPLog(counter + ".   " + file_name[0]);
			QueueDownload(current_download.full_address + file_name[0]);
		}
		counter += 1;
	}
}

void TCPLog(string message){
	Log(warning, message);
	log_data += message + "\n";
	ImGui_SetTextBuf(log_data);
}

void TCPLog(array<uint8>@ data){
	array<string> seperated;
	uint string_size = data.size();
    for( uint i = 0; i < string_size; i++ ){
		if((data[i] < 32 || data[i] > 126) && data[i] != 10){
			continue;
		}
		string s('0');
		s[0] = data[i];
		/* seperated.insertLast(data[i] + " "); */
		seperated.insertLast(s);
	}
	string new_line = join(seperated, "");
	log_data += new_line + "\n";
}

void ReadHeader(int body_index){
	array<string> header_lines = GetString(current_download.raw_data).split("\n");
	string length_line;

	for(uint i = 0; i < header_lines.size(); i++){
		if(header_lines[i].findFirst("Content-Length: ") != -1){
			length_line = header_lines[i];
			break;
		}
	}

	//Show the header in the log window.
	if(show_header){
		for(uint i = 0; i < header_lines.size(); i++){
			TCPLog(header_lines[i]);
		}
	}

	if(header_lines[0] != code_200){
		current_download.error = true;
		current_download.error_code = header_lines[0];
		return;
	}

	int header_size = body_index;
	string text = "";
	string numbers = "";

	for(uint i = 0; i < current_download.raw_data.size(); i++){
		string s('0');
		s[0] = current_download.raw_data[i];
		text += s;
		numbers += "" + current_download.raw_data[i];
		if(current_download.raw_data[i] == 10){
			/* Log(warning, "Header line text " + text);
			Log(warning, "Header line numbers" + numbers); */
			text = "";
			numbers = "";
		}
	}

	current_download.file_size = atoi(join(length_line.split("Content-Length: "), ""));
	TCPLog("File size : " + (current_download.file_size / 1024.0) + " kb");

	/* Log(warning, "Header size " + header_size); */

	current_download.raw_data.removeRange(0, header_size);
	/* TCPLog("From header " + GetString(current_download.raw_data)); */
	current_download.download_progress = current_download.raw_data.length();
	/* TCPLog("Progress : " + current_download.download_progress); */
}

array<string> ExtractStringBetween(string source, string first_string, string second_string){
	array<string> result;

	array<string> first_split = source.split(first_string);
	for(uint i = 1; i < first_split.size(); i++){
		array<string> second_split = first_split[i].split(second_string);
		result.insertLast(second_split[0]);
	}

	return result;
}

void WriteDownloadedFile(string folder){
	StartWriteFile();

	for(uint i = 0; i < current_download.raw_data.size(); i++){
		string s('0');
		s[0] = current_download.raw_data[i];
		AddFileString(s);
	}

	string save_file = folder + current_download.file_name + "." + current_download.file_extention;
	WriteFileToWriteDir(save_file);

	if(current_download.file_extention == "png" || current_download.file_extention == "jpg"){
		image = LoadTexture(save_file, TextureLoadFlags_NoMipmap | TextureLoadFlags_NoReduce);
	}
}

string GetString(array<uint8>@ data){
	array<string> seperated;
	uint string_size = data.size();
    for( uint i = 0; i < string_size; i++ ) {
		//Skip if the char is not an actual number/letter/etc
		/*if(data[i] < 32){
			continue;
		}*/
        string s('0');
        s[0] = data[i];
        seperated.insertLast(s);
    }
    return join(seperated, "");
}

void addToByteArray(string message, array<uint8> @data){
	uint8 message_length = message.length();
	data.insertLast(message_length);
	for(uint i = 0; i < message_length; i++){
		data.insertLast(message.substr(i, 1)[0]);
	}
}

array<uint8> toByteArray(string message){
	array<uint8> data;
	for(uint i = 0; i < message.length(); i++){
		data.insertLast(message.substr(i, 1)[0]);
	}
	return data;
}

void Menu(){
	ImGui_Checkbox("Show Download UI", show);
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
