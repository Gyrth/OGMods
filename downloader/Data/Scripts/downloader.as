string log_data = "";
uint16 api_port = 80;
uint main_socket = SOCKET_ID_INVALID;
bool show = true;
uint counter = 0;
array<uint8> raw_data;
string file_path;
string file_name;
string file_extention;
string server_address;
bool post_init_done = false;
float progress_interval_timer = 0.0;
float download_timer = 0.0;
bool downloading = false;
string progress_text = "";
bool has_header = false;
int file_size;
int download_progress = 0;
int packet_size = 0;
array<string> download_queue;
TextureAssetRef image = LoadTexture("Data/UI/spawner/thumbs/Hotspot/empty.png", TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce);

// Coloring options
vec4 edit_outline_color = vec4(0.5, 0.5, 0.5, 1.0);
vec4 background_color(0.25, 0.25, 0.25, 0.98);
vec4 titlebar_color(0.15, 0.15, 0.15, 0.98);
vec4 item_hovered(0.2, 0.2, 0.2, 0.98);
vec4 item_clicked(0.1, 0.1, 0.1, 0.98);
vec4 text_color(0.7, 0.7, 0.7, 1.0);

void Update(int paused){
	if(!post_init_done){
		PostInit();
		post_init_done = true;
	}
	if(downloading){
		progress_interval_timer += time_step;
		download_timer += time_step;

		if(progress_interval_timer > 0.2){
			/* Log(warning, "Progress " + download_progress); */

			progress_interval_timer = 0.0;
			UpdateProgressBar();
		}
	}else if(download_queue.size() > 0){
		Download(download_queue[0]);
		download_queue.removeAt(0);
	}
}

void UpdateProgressBar(){
	string size;

	if(download_progress > 10000000){
		size = (download_progress / 1024.0 / 1024.0) + " megabytes";
	}else if(download_progress > 1024){
		size = (download_progress / 1024.0) + " kilobytes";
	}else{
		size = download_progress + " bytes";
	}

	string percentage = (download_progress * 100 / max(file_size, 1)) + "% - ";
	string speed = ((download_progress / max(download_timer, 0.001)) / 1024.0) + " kb/s. ";

	progress_text = "Download : " + size + " " + percentage + speed + "\nLast packet size : " + packet_size + " bytes.";
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
	/* QueueDownload("107.173.129.154/moonwards/overgrowth.png"); */
	/* QueueDownload("107.173.129.154/moonwards/updates.json"); */
	/* QueueDownload("107.173.129.154/moonwards/steppes.jpg"); */
	/* QueueDownload("107.173.129.154/moonwards/fary.jpg"); */
}

void QueueDownload(string url){
	download_queue.insertLast(url);
}

void Download(string address){
	array<string> split_address = address.split("/");
	server_address = split_address[0];

	TCPLog("Downloading file : " + address);

	file_path = "";
	for(uint i = 1; i < split_address.size(); i++){
		file_path += "/" + split_address[i];
	}

	array<string> split_file_name = split_address[split_address.size() - 1].split(".");
	file_name = split_file_name[0];
	file_extention = split_file_name[1];

	SendRequest(server_address, "GET " + file_path + " HTTP/1.1\r\nHost: " + server_address + "\r\n\r\n");
}

void SendRequest(string address, string request){
	has_header = false;

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
	counter += data.size();

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
	}else if(has_header){
		download_progress += data.size();
		packet_size = data.size();

		if(download_progress >= file_size){
			//Done downloading!
			TCPLog("Download time : " + download_timer + " seconds.");
			TCPLog("Download speed : " + (file_size / download_timer) / 1024.0 + " kb/s.");
			TCPLog("-----------------------------------------------");
			UpdateProgressBar();

			download_timer = 0.0;
			WriteDownloadedFile();
			downloading = false;
			DestroySocketTCP(main_socket);
			main_socket = SOCKET_ID_INVALID;
			download_progress = 0;
			raw_data.resize(0);
		}
	}
}

void TCPLog(string message){
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
	array<string> header_lines = GetString(raw_data).split("\n");
	string length_line;

	for(uint i = 0; i < header_lines.size(); i++){
		if(header_lines[i].findFirst("Content-Length: ") != -1){
			length_line = header_lines[i];
			break;
		}
	}

	//Show the header in the log window.
	/* for(uint i = 0; i < header_lines.size(); i++){
		TCPLog(header_lines[i]);
	} */

	int header_size = body_index;
	string text = "";
	string numbers = "";

	for(uint i = 0; i < raw_data.size(); i++){
		string s('0');
		s[0] = raw_data[i];
		text += s;
		numbers += "" + raw_data[i];
		if(raw_data[i] == 10){
			/* Log(warning, "Header line text " + text);
			Log(warning, "Header line numbers" + numbers); */
			text = "";
			numbers = "";
		}
	}

	file_size = atoi(join(length_line.split("Content-Length: "), ""));
	TCPLog("File size : " + (file_size / 1024.0) + " kb");

	/* Log(warning, "Header size " + header_size); */

	raw_data.removeRange(0, header_size);
	Log(warning, "From header " + GetString(raw_data));
	download_progress = raw_data.length();
}

void WriteDownloadedFile(){
	StartWriteFile();

	for(uint i = 0; i < raw_data.size(); i++){
		string s('0');
		s[0] = raw_data[i];
		AddFileString(s);
	}

	string save_file = "Data/Downloads/" + file_name + "." + file_extention;
	WriteFileToWriteDir(save_file);
	if(file_extention == "png" || file_extention == "jpg"){
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
