
int character_id = -1;
bool has_camera_control = false;
float target_rotation = 0.0f;
float target_rotation2 = 0.0f;

void Update(int is_paused){
	if (has_camera_control){

		MovementObject@ mo = ReadCharacterID(character_id);
		vec3 facing = camera.GetFacing();
		vec3 cam_pos_offset = vec3(facing.z * -0.5, 0, facing.x * 0.5);
		vec3 shoulder_height = vec3(0.0f, 1.0f, 0.0f);
		camera.SetPos(mo.position + shoulder_height + cam_pos_offset);

	}
}

void Init(string str){
}

bool DialogueCameraControl() {
	return has_camera_control;
}

void ReceiveMessage(string msg) {
	TokenIterator token_iter;
	token_iter.Init();
	if(!token_iter.FindNextToken(msg)){
		return;
	}
	string token = token_iter.GetToken(msg);
	if(token == "gun_event"){
		token_iter.FindNextToken(msg);
		string gun_event = token_iter.GetToken(msg);
		if(gun_event == "gun_owner"){
			token_iter.FindNextToken(msg);
			string id_string = token_iter.GetToken(msg);
			character_id = int(parseInt(id_string));
		}else if(gun_event == "gun_aiming"){
			token_iter.FindNextToken(msg);
			string state = token_iter.GetToken(msg);
			if(state == "on"){
				Log(info, "aim on");
				has_camera_control = true;
			}else{
				Log(info, "aim off");
				has_camera_control = false;
			}
		}
	}
}
