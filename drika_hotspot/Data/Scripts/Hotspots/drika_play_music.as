enum music_events{	in_combat_music = 0,
					player_died_music = 1,
					enemies_defeated_music = 2
				}

class DrikaPlayMusic : DrikaElement{
	string music_path;
	string song_path;
	string song_name;
	string before_song;
	bool from_beginning_no_fade;
	bool on_event;
	int current_music_event;
	music_events music_event;

	array<string> music_event_names = { "In Combat", "Player Died", "Enemies Defeated" };

	DrikaPlayMusic(JSONValue params = JSONValue()){
		music_path = GetJSONString(params, "music_path", "Data/Music/drika_music.xml");
		song_path = GetJSONString(params, "song_path", "Data/Music/lugaru_menu_new.ogg");
		song_name = GetJSONString(params, "song_name", "lugaru_menu_new.ogg");
		from_beginning_no_fade = GetJSONBool(params, "from_beginning_no_fade", false);
		on_event = GetJSONBool(params, "on_event", false);

		music_event = music_events(GetJSONInt(params, "music_event", in_combat_music));
		current_music_event = music_event;

		drika_element_type = drika_play_music;
		has_settings = true;
	}

	JSONValue GetCheckpointData(){
		JSONValue data;
		data["triggered"] = triggered;
		if(triggered){
			data["current_song"] = JSONValue(GetSong());
		}
		return data;
	}

	void SetCheckpointData(JSONValue data = JSONValue()){
		triggered = data["triggered"].asBool();
		if(triggered){
			SetSong(data["current_song"].asString());
		}
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["music_path"] = JSONValue(music_path);
		data["song_path"] = JSONValue(song_path);
		data["song_name"] = JSONValue(song_name);
		data["from_beginning_no_fade"] = JSONValue(from_beginning_no_fade);
		data["on_event"] = JSONValue(on_event);
		data["music_event"] = JSONValue(music_event);
		return data;
	}

	string GetDisplayString(){
		string display_string = "PlayMusic ";
		if(on_event){
			display_string += music_event_names[music_event] + " ";
		}
		return display_string + song_name;
	}

	void DrawSettings(){

		float option_name_width = 175.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Song Path");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();

		if(ImGui_Button("Set Song Path")){
			string new_path = GetUserPickedReadPath("ogg", "Data/Music");
			if(new_path != ""){
				song_path = new_path;
				SongPathCheck();
				GetSongName();
				music_path = "Data/Music/" + GetUniqueFileName() + ".xml";
				WriteMusicXML();
				Play(false);
			}
		}
		ImGui_SameLine();
		ImGui_Text(song_path);
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("From Beginning No Fade");
		ImGui_NextColumn();
		ImGui_Checkbox("###From Beginning No Fade", from_beginning_no_fade);
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("On Event");
		ImGui_NextColumn();
		ImGui_Checkbox("###On Event", on_event);
		ImGui_NextColumn();

		if(on_event){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Music Event");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_Combo("##Music Event", current_music_event, music_event_names, music_event_names.size())){
				music_event = music_events(current_music_event);
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}
	}

	void GetSongName(){
		array<string> split_path = song_path.split("/");
		song_name = split_path[split_path.size() - 1];
	}

	bool Trigger(){
		if(!triggered){
			GetPreviousSong();
		}
		triggered = true;
		return Play(false);
	}

	string GetUniqueFileName(){
		string filename = "";
		while(filename.length() < 10){
			string s('0');
	        s[0] = rand() % (123 - 97) + 97;
	        filename += s;
		}
		if(FileExists("Data/Music/" + filename + ".xml")){
			//Already exists so get a new one.
			return GetUniqueFileName();
		}else{
			return filename;
		}
	}

	void WriteMusicXML(){
		string msg = "write_music_xml ";
		msg += music_path + " ";
		msg += song_name + " ";
		msg += song_path;

		level.SendMessage(msg);
	}

	void GetPreviousSong(){
		before_song = GetSong();
	}

	void StartEdit(){
		Play(false);
	}

	void SongPathCheck(){
		if(!FileExists(song_path)){
			array<string> split_path = song_path.split("/");
			split_path.removeRange(0, 2);
			string new_path = join(split_path, "/");
			if(FileExists(song_path)){
				Log(warning, "Fixed path " + new_path);
				song_path = new_path;
			}
		}
	}

	bool Play(bool reset){
		SongPathCheck();
		if(reset){
			RemoveMusic(music_path);
		}else{
			if(!FileExists(music_path)){
				WriteMusicXML();
			}
			AddMusic(music_path);
		}

		if(on_event){
			level.SendMessage("drika_music_event " + music_event + " " + (reset?before_song:song_name) + " " + from_beginning_no_fade);
		}else{
			if(from_beginning_no_fade){
				SetSong((reset?before_song:song_name));
			}else{
				PlaySong((reset?before_song:song_name));
			}
		}

		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			Play(true);
		}
	}
}
