class DrikaPlayMusic : DrikaElement{
	string music_path;
	string song;
	string before_song;

	DrikaPlayMusic(string _music_path = "Data/Music/lugaru.xml", string _song = "lugaru_menu"){
		placeholder_name = "Play Sound Helper";
		music_path = _music_path;
		song = _song;
		drika_element_type = drika_play_music;
		AddMusic(music_path);
		has_settings = true;
	}

	string GetSaveString(){
		return "play_music" + param_delimiter + music_path + param_delimiter + song;
	}

	string GetDisplayString(){
		return "PlayMusic " + music_path + " " + song;
	}

	void AddSettings(){
		ImGui_Text("Music Path : ");
		ImGui_SameLine();
		ImGui_Text(music_path);
		if(ImGui_Button("Set Music Path")){
			string new_path = GetUserPickedReadPath("wav", "Data/Music");
			if(new_path != ""){
				music_path = new_path;
				AddMusic(music_path);
			}
		}
		ImGui_InputText("Song", song, 64);
	}

	bool Trigger(){
		if(!triggered){
			GetPreviousSong();
		}
		triggered = true;
		return Play(false);
	}

	void GetPreviousSong(){
		before_song = GetSong();
	}

	bool Play(bool reset){
		Log(info, "Set song " + (reset?before_song:song));
		if(reset){
			RemoveMusic(music_path);
		}
		PlaySong((reset?before_song:song));
		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			Play(true);
		}
	}
}
