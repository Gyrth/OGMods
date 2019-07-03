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
array<ModData@> sorted_mods;
string search_query = "";
bool sort_mods = false;

bool post_init_done = false;
float progress_interval_timer = 0.0;
bool downloading = false;
string progress_text = "";
int selected_mod = 0;
int new_selected_mod = 0;
string server_address = "107.173.129.154/downloader/";
bool show_local_mods = true;
bool show_remote_mods = true;

const string code_404 = "HTTP/1.1 404 ERROR ";
const string code_200 = "HTTP/1.1 200 OK\r";

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
	string remote_path = "";
	TextureAssetRef thumbnail;
	string description = "";
	bool is_installed = false;
	bool is_enabled = false;
	bool has_mod_id = false;
	bool can_activate = false;
	bool is_remote_mod = false;
	bool is_local_mod = false;
	bool is_installing = false;
	bool getting_thumbnail = false;
	bool has_error = false;
	bool refresh = false;
	bool has_dependencies = false;
	string source_description;
	ModID mod_id;
	string error;
	Download@ download = null;
	Download@ thumbnail_download = null;
	string dependencies;
	array<ModData@> dependencies_mod_data;
	ModData@ target;

	ModData(string name, string id, string version, string author, string thumbnail_path, string description, string remote_path, bool is_remote_mod, string dependencies){
		this.name = name;
		this.id = id;
		this.version = version;
		this.author = author;
		this.description = description;
		this.is_remote_mod = is_remote_mod;
		this.remote_path = remote_path;
		this.dependencies = dependencies;

		CheckLocalMod();

		if(is_remote_mod){
			this.remote_thumbnail_path = thumbnail_path;
		}else{
			local_thumbnail_path = thumbnail_path;
		}
	}

	void Install(ModData@ target = null){
		if(!is_remote_mod){
			return;
		}

		if(@target != null){
			@this.target = @target;
		}

		is_installing = true;
		if(dependencies_mod_data.size() != 0){
			for(uint i = 0; i < dependencies_mod_data.size(); i++){
				if(!dependencies_mod_data[i].is_installed){
					dependencies_mod_data[i].Install(this);
					return;
				}
			}
		}

		if(@download == null){
			@download = Download(server_address + remote_path);
		}
	}

	void Activation(bool enable, bool include_dependencies = true){
		if(has_dependencies && include_dependencies){
			for(uint i = 0; i < dependencies_mod_data.size(); i++){
				dependencies_mod_data[i].Activation(enable);
			}
		}
		ModActivation(mod_id, enable);
		refresh = true;
	}

	Download@ GetNextDownload(){
		if(@thumbnail_download != null){
			Download@ next_download = thumbnail_download.GetNextDownload();
			if(@next_download == null){
				@thumbnail_download = null;
			}else{
				return next_download;
			}
		}

		if(@download != null){
			Download@ next_download = download.GetNextDownload();
			if(@next_download == null){
				ShowNotification("Mod download done : " + name);
				is_installing = false;
				@download = null;
				ReloadMods();
				UpdateStatus();
				if(@target != null){
					target.Install();
				}
			}
			return next_download;
		}else{
			return null;
		}
	}

	void CheckLocalMod(){
		array<ModID>all_mods = GetModSids();
		for(uint i = 0; i < all_mods.size(); i++){
			if(ModGetID(all_mods[i]) == id){
				is_local_mod = true;
				mod_id = all_mods[i];
				has_mod_id = true;
				break;
			}
		}
	}

	void UpdateStatus(){
		CheckLocalMod();

		error = "";
		has_error = false;
		can_activate = false;

		if(dependencies != ""){
			array<string> dependencies_ids = dependencies.split(",");
			for(uint i = 0; i < dependencies_ids.size(); i++){
				for(uint j = 0; j < mods.size(); j++){
					if(mods[j].id == dependencies_ids[i]){
						dependencies_mod_data.insertLast(mods[j]);
						break;
					}else if(j == mods.size() - 1){
						error += "Could not find dependency : " + dependencies_ids[i];
						has_error = true;
					}
				}
			}
			has_dependencies = dependencies_mod_data.size() != 0;
		}

		if(has_mod_id){
			is_installed = true;
			if(ModIsActive(mod_id)){
				is_enabled = true;
			}else{
				is_enabled = false;
			}

			if(ModCanActivate(mod_id)){
				can_activate = true;
			}
			//If this mod has dependencies then check if the dependencies can be enabled as well.
			if(dependencies_mod_data.size() != 0){
				for(uint i = 0; i < dependencies_mod_data.size(); i++){
					if(!ModCanActivate(dependencies_mod_data[i].mod_id)){
						can_activate = false;
					}
				}
			}

			error += ModGetValidityString(mod_id);
			if(error.length() > 0){
				has_error = true;
			}

		}else{
			is_installed = false;
		}

		if(is_local_mod){
			source_description = "Local";
			if(is_remote_mod){
				source_description += " and Remote";
			}
		}else if(is_remote_mod){
			source_description = "Remote";
		}
	}

	void ReloadThumbnail(){
		if(is_remote_mod){
			array<string> split_path = remote_thumbnail_path.split("/");
			local_thumbnail_path = "Data/Downloads/Thumbnails/" + split_path[split_path.size() - 1];
			if(!FileExists(local_thumbnail_path) && @download == null){
				getting_thumbnail = true;
				@thumbnail_download = Download(remote_thumbnail_path, this);
			}
		}

		if(FileExists(local_thumbnail_path)){
			getting_thumbnail = false;
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
	string local_file_path;
	string file_name;
	string file_extention;
	string server_address;
	bool has_header = false;
	bool error = false;
	bool download_done = false;
	string error_code = "";
	int file_size;
	int download_progress = 0;
	int packet_size = 0;
	float download_timer = 0.0;
	download_types download_type;
	array<Download@> download_queue;
	ModData@ target;

	Download(string full_address, ModData@ target = null){
		this.full_address = full_address;
		@this.target = target;

		array<string> split_address = full_address.split("/");
		server_address = split_address[0];
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

		for(uint i = 1; i < split_address.size(); i++){
			file_path += "/" + split_address[i];
		}

		for(uint i = 2; i < split_address.size() - 1; i++){
			local_file_path += "/" + split_address[i];
		}

		array<string> split_file_name = split_address[split_address.size() - 1].split(".");
		file_name = split_file_name[0];
		if(split_file_name.size() > 1){
			file_extention = split_file_name[1];
		}
	}

	Download@ GetNextDownload(){
		if(download_queue.size() > 0){
			Download@ next_download = download_queue[0].GetNextDownload();
			if(@next_download == null){
				download_queue.removeAt(0);
				return GetNextDownload();
			}
			return next_download;
		}else if(!download_done){
			return this;
		}else{
			return null;
		}
	}

	bool ReadData(array<uint8>@ data){
		if(download_queue.size() > 0){
			if(download_queue[0].ReadData(data)){
				download_queue.removeAt(0);

			}
		}else if(!download_done){

			for(uint i = 0; i < data.size(); i++){
				raw_data.insertLast(data[i]);
			}

			if(!has_header){
				//Check if the whole head has been received.
				for(uint i = 0; i < raw_data.size() - 2; i++){
					if(raw_data[i] == 13 && raw_data[i + 1] == 10 && raw_data[i + 2] == 13){
						has_header = true;
						ReadHeader(i + 4);
						break;
					}
				}
			}else if(error){
				TCPLog("Error downloading : " + error_code);
				TCPLog("-----------------------------------------------");
				ClearSocket();
				download_done = true;
				return true;
			}else if(has_header){
				download_progress += data.size();
				packet_size = data.size();

				if(download_progress >= file_size){
					//Done downloading!
					TCPLog("Download done : " + full_address);
					TCPLog("Download size : " + download_progress + " bytes.");
					TCPLog("Download time : " + download_timer + " seconds.");
					TCPLog("Download speed : " + (file_size / max(0.001, download_timer)) / 1024.0 + " kb/s.");
					TCPLog("-----------------------------------------------");
					UpdateProgressBar();
					ClearSocket();

					if(download_type == thumbnail){
						WriteDownloadedFile("Data/Downloads/Thumbnails/");
						target.ReloadThumbnail();
					}else if(download_type == file){
						WriteDownloadedFile("Data/Mods" + local_file_path + "/");
					}else if(download_type == directory){
						DownloadFilesInDirectory();
					}else if(download_type == mod_list){
						TCPLog("Read Mod list");
						ReadModList();
					}
					download_done = true;
					return true;
				}
			}
		}
		return false;
	}

	void DownloadFilesInDirectory(){
		array<string> result = ExtractStringBetween(GetString(raw_data), "<tr>", "</tr>");

		TCPLog("Directory list : ");
		int counter = 0;
		//Skip the first 3 lines since those are headers.
		for(uint i = 3; i < result.size(); i++){
			array<string> file_name = ExtractStringBetween(result[i], "<a href=\"", "\">");
			if(file_name.size() > 0){
				TCPLog(counter + ".   " + file_name[0]);
				download_queue.insertLast(Download(full_address + file_name[0]));
			}
			counter += 1;
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
	if(@current_download != null){
		progress_interval_timer += time_step;
		current_download.download_timer += time_step;

		if(progress_interval_timer > 0.2){
			/* Log(warning, "Progress " + download_progress); */

			progress_interval_timer = 0.0;
			UpdateProgressBar();
		}
	}else{
		for(uint i = 0; i < mods.size(); i++){
			if(@mods[i].GetNextDownload() != null){
				@current_download = mods[i].GetNextDownload();
				TCPLog("Downloading file : " + current_download.full_address);
				SendRequest(current_download.server_address, "GET " + current_download.file_path + " HTTP/1.1\r\nHost: " + current_download.server_address + "\r\n\r\n");
				break;
			}else if(mods[i].refresh){
				mods[i].UpdateStatus();
				mods[i].ReloadThumbnail();
				mods[i].refresh = false;
			}
		}
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
	if(sort_mods){
		SortMods();
		sort_mods = false;
	}
	if(new_selected_mod != selected_mod){
		selected_mod = new_selected_mod;
	}
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
						mods[i].Activation(false);
					}
				}
				if(ImGui_MenuItem("Enable All Mods")){
					for(uint i = 0; i < mods.size(); i++){
						mods[i].Activation(true);
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

		if(tab == download){
			//Add the searchbar.
			ImGui_SetNextWindowPos(ImGui_GetCursorScreenPos());
			float searchbar_width = ImGui_GetWindowWidth() / 2.0 - 15.0;
			ImGui_BeginChild("Searchbar", vec2(searchbar_width, 25.0f), false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);

			ImGui_PushItemWidth(50);
			ImGui_LabelText("###Search:", "Search:");
			ImGui_PopItemWidth();
			ImGui_SameLine();
			ImGui_PushItemWidth(searchbar_width - 225.0);
			ImGui_SetTextBuf(search_query);
			if(ImGui_InputText("##Search:", search_query, 64, ImGuiInputTextFlags_AutoSelectAll)){
				sort_mods = true;
			}
			ImGui_PopItemWidth();

			//Get the cursor position so that the empty can be drawn at the end of the searchbar.
			ImGui_SameLine();
			vec2 empty_button_start = ImGui_GetCursorScreenPos();
			empty_button_start.x -= 28.0;

			//Add the checkboxes to include remote and local mods.
			ImGui_PushItemWidth(100);
			if(ImGui_Checkbox("Local", show_local_mods)){
				sort_mods = true;
			}
			ImGui_SameLine();
			if(ImGui_Checkbox("Remote", show_remote_mods)){
				sort_mods = true;
			}
			ImGui_PopItemWidth();

			if(search_query != ""){
				ImGui_SameLine();

				ImGui_SetNextWindowPos(empty_button_start);
				ImGui_BeginChild("EmptyButton", vec2(20.0, 20.0), false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);

				if(ImGui_InvisibleButton("EmptyButton", vec2(20.0, 20.0))){
					search_query = "";
					sort_mods = true;
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

			for(uint i = 0; i < sorted_mods.size(); i++){

				vec2 name_title_pos;
				ImGui_Spacing();
				if(selected_mod == int(i)){
					ImGui_PushStyleColor(ImGuiCol_ChildWindowBg, item_hovered);
				}

				ImGui_BeginChild(sorted_mods[i].id, mod_button_size, true, ImGuiWindowFlags_NoScrollWithMouse);
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

				ImGui_Image(sorted_mods[i].thumbnail, vec2(150, 100));
				ImGui_NextColumn();
				ImGui_TextWrapped(sorted_mods[i].description);

				ImGui_EndChild();
				vec3 text_color = vec3(1, 1, 1);
				if(sorted_mods[i].is_enabled){
					text_color = vec3(0.65, 1, 0.65);
				}else if(!sorted_mods[i].can_activate){
					text_color = vec3(1, 0.65, 0.65);
				}

				mod_list_labels.insertLast(LabelData(sorted_mods[i].name + " - " + sorted_mods[i].author, name_title_pos, text_color, background_color));
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

			if(sorted_mods.size() > 0){
				float section_height = ImGui_GetWindowHeight() - 10.0;

				ImGui_BeginChild("Thumbnail", vec2(-1.0, section_height / 3.0), false, ImGuiWindowFlags_NoScrollWithMouse);
				float image_height = section_height / 3.0 - 10.0f;
				ImGui_Indent(ImGui_GetWindowWidth() / 2.0f - image_height);
				ImGui_Image(sorted_mods[selected_mod].thumbnail, vec2(image_height * 2.0f, image_height));
				ImGui_EndChild();

				ImGui_BeginChild("Install", vec2(-1.0, sorted_mods[selected_mod].has_error?100.0:40.0), true);
				inspector_labels.insertLast(LabelData(sorted_mods[selected_mod].name, ImGui_GetWindowPos() + vec2(20.0, -7.0), vec3(1, 1, 1), background_color));

				ImGui_Spacing();

				if(sorted_mods[selected_mod].is_installing){
					ImGui_TextWrapped("Installing...");
				}else if(!sorted_mods[selected_mod].has_error){
					if(!sorted_mods[selected_mod].is_installed){
						if(ImGui_Button("Install")){
							sorted_mods[selected_mod].Install();
						}
					}else{
						if(sorted_mods[selected_mod].is_enabled){
							if(ImGui_Button("Disable ")){
								sorted_mods[selected_mod].Activation(false, false);
							}
							ImGui_SameLine();
							if(sorted_mods[selected_mod].has_dependencies){
								if(ImGui_Button("Disable including dependencies")){
									sorted_mods[selected_mod].Activation(false);
								}
								ImGui_SameLine();
							}
						}else{

							if(sorted_mods[selected_mod].can_activate){
								if(ImGui_Button("Enable")){
									sorted_mods[selected_mod].Activation(true);
								}
								ImGui_SameLine();
							}
						}
						if(sorted_mods[selected_mod].is_remote_mod){
							if(ImGui_Button("ReInstall")){
								sorted_mods[selected_mod].Install();
							}
							ImGui_SameLine();
							if(sorted_mods[selected_mod].version != sorted_mods[selected_mod].remote_version){
								if(ImGui_Button("Update")){
									sorted_mods[selected_mod].Install();
								}
								ImGui_SameLine();
							}
						}
					}
				}
				if(sorted_mods[selected_mod].has_error){
					ImGui_PushStyleColor(ImGuiCol_Text, vec4(1.0, 0.65, 0.65, 1.0));
					ImGui_TextWrapped(sorted_mods[selected_mod].error);
					ImGui_PopStyleColor();
				}
				ImGui_EndChild();
				ImGui_Spacing();

				ImGui_BeginChild("Details", vec2(-1, 70.0), true, ImGuiWindowFlags_NoScrollWithMouse);
				inspector_labels.insertLast(LabelData("Details", ImGui_GetWindowPos() + vec2(20.0, -7.0), vec3(1, 1, 1), background_color));

				ImGui_Columns(2, false);

				ImGui_Text("Author : " + sorted_mods[selected_mod].author);
				ImGui_Text("ID : " + sorted_mods[selected_mod].id);
				ImGui_Text("Version : " + sorted_mods[selected_mod].version);

				ImGui_NextColumn();

				ImGui_Text("Status : " + "Not installed");
				ImGui_Text("Source : " + sorted_mods[selected_mod].source_description);
				ImGui_Text("Dependencies : " + sorted_mods[selected_mod].dependencies);

				ImGui_EndChild();
				ImGui_Spacing();

				ImGui_BeginChild("Description", vec2(-1.0, -1.0), true, ImGuiWindowFlags_NoScrollWithMouse);
				inspector_labels.insertLast(LabelData("Description", ImGui_GetWindowPos() + vec2(20.0, -7.0), vec3(1, 1, 1), background_color));

				ImGui_TextWrapped(sorted_mods[selected_mod].description);
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

		ImGui_PushStyleVar(ImGuiStyleVar_Alpha, 0.75f);
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

void SortMods(){
	sorted_mods.resize(0);
	new_selected_mod = 0;
	string query_lower = ToLowerCase(search_query);

	for(uint i = 0; i < mods.size(); i++){
		if(mods[i].is_local_mod && show_local_mods || mods[i].is_remote_mod && show_remote_mods){
			if(ToLowerCase(mods[i].name).findFirst(query_lower) != -1 || ToLowerCase(mods[i].id).findFirst(query_lower) != -1 || ToLowerCase(mods[i].author).findFirst(query_lower) != -1){
				sorted_mods.insertLast(mods[i]);
			}
		}
	}
}

void Init(string level_name){
}

void PostInit(){
	ReadLocalMods();
	GetRemoteMods();
}

void GetRemoteMods(){
	@current_download = Download(server_address + "mod_list.json");
	SendRequest(current_download.server_address, "GET " + current_download.file_path + " HTTP/1.1\r\nHost: " + current_download.server_address + "\r\n\r\n");
}

void ReadLocalMods(){
	array<ModID> all_mods = GetModSids();

	for(uint i = 0; i < all_mods.size(); i++){
		ModData mod(ModGetName(all_mods[i]),ModGetID(all_mods[i]), ModGetVersion(all_mods[i]), ModGetAuthor(all_mods[i]), ModGetThumbnail(all_mods[i]), ModGetDescription(all_mods[i]), "", false, "");
		mods.insertLast(@mod);
		mod.refresh = true;
	}
	sort_mods = true;
}

void SendRequest(string address, string request){
	/* Log( info, "Request " + address + request); */
	if( main_socket == SOCKET_ID_INVALID ) {
		main_socket = CreateSocketTCP(address, api_port);
        if( main_socket != SOCKET_ID_INVALID ) {
            Log( info, "Connected " + main_socket );
			array<uint8> message = toByteArray(request);
			if( IsValidSocketTCP(main_socket) ){
		        SocketTCPSend(main_socket, message);
			}
        } else {
            Log( warning, "Unable to connect" );
        }
    }
}

void IncomingTCPData(uint socket, array<uint8>@ data) {
	//Once the download completes it return true.
	if(@current_download != null){
		if(current_download.ReadData(data)){
			@current_download = null;
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
				mods[j].remote_path = mod_data["Directory"].asString();
				mods[j].dependencies = mod_data["Dependencies"].asString();
				already_local = true;
				mods[j].refresh = true;
				break;
			}
		}

		if(already_local){
			continue;
		}

		ModData mod(mod_data["Name"].asString(), mod_data["ID"].asString(), mod_data["Version"].asString(), mod_data["Author"].asString(), mod_data["Thumbnail"].asString(), mod_data["Description"].asString(), mod_data["Directory"].asString(), true, mod_data["Dependencies"].asString());
		mods.insertLast(@mod);
		mod.refresh = true;
	}
	sort_mods = true;
}

void ClearSocket(){
	DestroySocketTCP(main_socket);
	main_socket = SOCKET_ID_INVALID;
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
