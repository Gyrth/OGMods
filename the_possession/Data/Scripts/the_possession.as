MovementObject@ player;
MovementObject@ possess_char;
bool post_init_done = false;
control_modes control_mode = bound;
float original_fov = 90.0f;
vec3 camera_velocity = vec3();
float x_rotation = 0.0f;
float y_rotation = 0.0f;
float z_rotation = 0.0f;
vec2 camera_rotation_velocity;
ScriptParams@ level_params;
float fov = 90.0f;
float move_in_timer;
vec3 move_from;
float particle_timer = 0.0f;
int ghost_sound;

enum control_modes 	{
						floating,
						bound,
						move_in_possess
					}

void Init(string level_name){
}

void PostInit(){
	original_fov = camera.GetFOV();
	@level_params = level.GetScriptParams();
	for(int i = 0; i < GetNumCharacters(); i++){
		MovementObject@ char = ReadCharacter(i);
		if(char.is_player){
			@player = char;
			break;
		}
	}
}

void Update(int is_paused){
	if(!post_init_done){
		PostInit();
		post_init_done = true;
	}

	if(EditorModeActive()){
		return;
	}

	if(control_mode != move_in_possess){
		if(GetInputPressed(0, "g")){
			// Switch mode.
			if(control_mode == bound){
				control_mode = floating;
				ghost_sound = PlaySoundLoop("Data/Sounds/ouran/roomtone.wav", 0.25f);
				int start_sound = PlaySound("Data/Sounds/ghost_start.wav");
				SetSoundGain(start_sound, 0.15f);
				camera_velocity = vec3();
				camera_velocity = vec3();
				x_rotation = camera.GetXRotation();
				y_rotation = camera.GetYRotation();
				z_rotation = camera.GetZRotation();
				level_params.SetFloat("Saturation", 0.0f);
				level_params.SetFloat("HDR Black point", 0.01);
			}else if(control_mode == floating && PossessCheck()){
				control_mode = move_in_possess;
				move_in_timer = 0.0f;
				move_from = camera.GetPos();
				int end_sound = PlaySound("Data/Sounds/ghost_end.wav");
				SetSoundGain(end_sound, 0.15f);
			}
		}
	}

	if(control_mode == floating){
		UpdateFloatingControls();
		UpdateListener(camera.GetPos(), vec3(0, 0, 0), camera.GetFacing(), camera.GetUpVector());
		CreatePossessedParticle(camera.GetPos());
	}else if(control_mode == move_in_possess){
		float move_in_duration = 0.5;
		vec3 camera_position = mix(move_from, possess_char.position + vec3(0.0, 0.5, 0.0), move_in_timer / move_in_duration);
		camera.SetPos(camera_position);
		camera.SetXRotation(x_rotation);
		camera.SetYRotation(y_rotation);
	    camera.SetZRotation(z_rotation);
	    camera.CalcFacing();

		if(move_in_timer >= move_in_duration){
			control_mode == bound;
			fov = original_fov;
			control_mode = bound;
			player.Execute("target_rotation = " + y_rotation + ";");
			player.Execute("target_rotation2 = " + x_rotation + ";");
			player.Execute("cam_rotation = " + y_rotation + ";");
			player.Execute("cam_rotation2 = " + x_rotation + ";");
			level_params.SetFloat("Saturation", 1.0f);
			/* level_params.SetFloat("HDR Black point", 0.005); */
			StopSound(ghost_sound);

			if(possess_char !is player){
				possess_char.is_player = true;
				possess_char.controlled = true;
				player.is_player = false;
				player.controlled = false;
				@player = possess_char;
				player.Execute("this_mo.RecreateRiggedObject(this_mo.char_path);");
			}
		}
		move_in_timer += time_step;
		UpdateListener(camera.GetPos(), vec3(0, 0, 0), camera.GetFacing(), camera.GetUpVector());
	}else if(control_mode == bound){
		vec3 particle_position = player.position + vec3(0.0, 0.5, 0.0);
		CreatePossessedParticle(particle_position);
	}
}

void CreatePossessedParticle(vec3 location){
	if(particle_timer >= 0.1){
		particle_timer = 0.0f;
		vec3 velocity = vec3(RangedRandomFloat(-1.0, 1.0), RangedRandomFloat(-1.0, 1.0), RangedRandomFloat(-1.0, 1.0)) * 2.0f;
		MakeParticle("Data/Particles/possessed.xml", location, velocity, vec3(0.0, 0.0, 0.0));
	}
	particle_timer += time_step;
}

bool PossessCheck(){
	vec3 look_direction = camera.GetFacing();
	vec3 camera_position = camera.GetPos();
	float lowest_dot = 99.0f;
	MovementObject@ target_char = null;

	for(int i = 0; i < GetNumCharacters(); i++){
		MovementObject@ char = ReadCharacter(i);
		vec3 check_pos = char.position + vec3(0.0, 0.5, 0.0);
		vec3 direction = normalize(camera_position - check_pos);
		float dot_product = dot(direction, look_direction);

		if(1.0 + dot_product < 0.1){
			if(lowest_dot > dot_product){
				@target_char = char;
			}
		}
	}

	if(target_char !is null){
		@possess_char = target_char;
		return true;
	}

	return false;
}

void DrawGUI() {
}

void SetWindowDimensions(int w, int h)
{
}

void UpdateFloatingControls(){
	fov = mix(120.0f, fov, (1.0f - (time_step * 5.0f)));
	camera.SetFOV(fov);

	vec3 forward_direction = camera.GetFacing();
	vec3 left_direction = vec3(forward_direction.z, 0.0f, -forward_direction.x);
	vec3 current_position = camera.GetPos();
	float speed = 0.05f;
	float rotation_speed = 0.5f;

	camera_velocity -= GetMoveYAxis(player.controller_id) * forward_direction * speed;
	camera_velocity -= GetMoveXAxis(player.controller_id) * left_direction * speed;
	camera.SetPos(current_position + (camera_velocity * time_step));
	camera.SetDistance(0.0f);
	camera_velocity *= (1.0f - (time_step * 1.0f));

	camera_rotation_velocity += vec2(GetLookXAxis(player.controller_id), GetLookYAxis(player.controller_id)) * rotation_speed;

	x_rotation -= (camera_rotation_velocity.y * time_step);
	camera.SetXRotation(x_rotation);
	y_rotation -= (camera_rotation_velocity.x * time_step);
	camera.SetYRotation(y_rotation);
    camera.SetZRotation(z_rotation);
    camera.CalcFacing();

	camera_rotation_velocity *= (1.0f - (time_step * 1.0f));
}

bool DialogueCameraControl(){
	if(control_mode == floating || control_mode == move_in_possess){
		return true;
	}else{
		return false;
	}
}
