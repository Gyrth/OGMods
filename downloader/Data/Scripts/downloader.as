string log_data = "";
uint16 api_port = 80;
uint main_socket = SOCKET_ID_INVALID;
bool show = true;
bool show_header = true;

bool post_init_done = false;
float progress_interval_timer = 0.0;
bool downloading = false;
string progress_text = "";

const string code_404 = "HTTP/1.1 404 ERROR ";
const string code_200 = "HTTP/1.1 200 OK\r";

array<Download@> download_queue;
Download@ current_download;
TextureAssetRef image = LoadTexture("Data/UI/spawner/thumbs/Hotspot/empty.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

// Coloring options
vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);
vec4 background_color(0.25, 0.25, 0.25, 0.98);
vec4 titlebar_color(0.15, 0.15, 0.15, 0.98);
vec4 item_hovered(0.2, 0.2, 0.2, 0.98);
vec4 item_clicked(0.1, 0.1, 0.1, 0.98);
vec4 text_color(0.7, 0.7, 0.7, 1.0);

enum download_types {
						file = 0,
						directory = 1
					};

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

	Download(string full_address){
		this.full_address = full_address;
		//If the name ends with / then it's a subdirectory.
		if(full_address.substr(full_address.length() -1, 1) == "/"){
			download_type = directory;
		}else{
			download_type = file;
		}
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
	if(show){
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
		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(300, 300));

		ImGui_SetNextWindowSize(vec2(600.0f, 400.0f), ImGuiSetCond_FirstUseEver);
		ImGui_SetNextWindowPos(vec2(100.0f, 100.0f), ImGuiSetCond_FirstUseEver);
		ImGui_Begin("Downloader " + "###Downloader", show, ImGuiWindowFlags_MenuBar);
		ImGui_PopStyleVar();

		if(ImGui_BeginMenuBar()){
			/* if(ImGui_BeginMenu("Add")){
				ImGui_EndMenu();
			} */
			if(ImGui_Button("Start Download")){
				QueueDownload("107.173.129.154/moonwards/fary.jpg");
			}
			ImGui_EndMenuBar();
		}

		ImGui_TextWrapped(log_data);

		ImGui_Text(progress_text);

		ImGui_Image(image, vec2(902, 507));

		ImGui_End();
		ImGui_PopStyleColor(17);
	}
}

void Init(string level_name){
}

void PostInit(){
	/* QueueDownload("wolfire.com/overgrowth/smalltitle.png"); */
	/* QueueDownload("107.173.129.154/moonwards/star.png"); */
	/* QueueDownload("107.173.129.154/moonwards/hart.png"); */
	/* QueueDownload("gyrthmcmulin.me/images/youtube.png"); */
	/* QueueDownload("gyrthmcmulin.me/videos/landmine.mp4"); */
	/* QueueDownload("107.173.129.154/downloader/overgrowth.png"); */
	/* QueueDownload("107.173.129.154/moonwards/updates.json"); */
	/* QueueDownload("107.173.129.154/moonwards/steppes.jpg"); */
	/* QueueDownload("107.173.129.154/downloader/fary.jpg"); */
	QueueDownload("107.173.129.154/downloader/");
	/* QueueDownload("raw.githubusercontent.com/Gyrth/OGMods/drika_hotspot/drika_hotspot/Data/Scripts/Hotspots/drika_element.as"); */
}

void QueueDownload(string full_address){
	download_queue.insertLast(Download(full_address));
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

			if(current_download.download_type == file){
				WriteDownloadedFile();
			}else if(current_download.download_type == directory){
				DownloadFilesInDirectory();
			}
			ClearDownload();
		}
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
	TCPLog("From header " + GetString(current_download.raw_data));
	current_download.download_progress = current_download.raw_data.length();
	TCPLog("Progress : " + current_download.download_progress);
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

void WriteDownloadedFile(){
	StartWriteFile();

	for(uint i = 0; i < current_download.raw_data.size(); i++){
		string s('0');
		s[0] = current_download.raw_data[i];
		AddFileString(s);
	}

	string save_file = "Data/Downloads/" + current_download.file_name + "." + current_download.file_extention;
	WriteFileToWriteDir(save_file);

	if(current_download.file_extention == "png" || current_download.file_extention == "jpg"){
		Log(warning, "Image : " + save_file);
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
