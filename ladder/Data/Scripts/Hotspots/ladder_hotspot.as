
array <int> steps;
float current_step_size = 1.0f;

void Init() { }

void SetParameters() {
	params.AddFloatSlider("Step size", 0.25f, "min:0.01,max:10.0,step:0.1,text_mult:1");
	params.AddString("Step path", "Data/Objects/block.xml");
}

class StepType{
	string path;
	StepType(string _path){
		path = _path;
	}
}

class User{
	int id = -1;
	int controller_id;
	vec3 current_position;
	User(MovementObject@ mo){
		id = mo.GetID();
		controller_id = mo.controller_id;
		current_position = mo.position;
	}
}

array<StepType@> step_types = {		StepType("Data/Objects/ladder2_mid.xml")};
array<User@> users;

void SetEnabled(bool is_enabled) { }

void Reset() { }

void Dispose() { }

void Update() {
	Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
	if(hotspot_obj.IsSelected()){
		ScriptParams@ params = hotspot_obj.GetScriptParams();
		float target_ladder_size = floor(hotspot_obj.GetScale().y * 4.0f / current_step_size);
		uint max_steps = uint(max(1.0, floor(target_ladder_size / max(1.0, current_step_size))));
		// If the parameter has changed then just delete all steps and built the ladder again.
		if(current_step_size != params.GetFloat("Step size") && current_step_size != 0.0f){
			current_step_size = params.GetFloat("Step size");
			ClearSteps();
		// If the ladder doesn't contain enough steps to fill the whole height, then add one step.
		}else if(steps.size() < max_steps){
			AddStep();
		}else if(steps.size() > max_steps){
			RemoveStep();
		}
		UpdateStepPositions();
	}
	UpdateUsers();
}

void UpdateUsers(){
	for (uint i = 0; i < users.size(); i++){
		if(GetInputDown(users[i].controller_id, "w") && !GetInputDown(users[i].controller_id, "s")){
			users[i].current_position += vec3(0.0, 1.0, 0.0) * time_step;
		}else if(!GetInputDown(users[i].controller_id, "w") && GetInputDown(users[i].controller_id, "s")){
			users[i].current_position -= vec3(0.0, 1.0, 0.0) * time_step;
		}
		MovementObject@ mo = ReadCharacterID(users[i].id);
		mo.ReceiveMessage("set_dialogue_position " + users[i].current_position.x + " " +  users[i].current_position.y + " " + users[i].current_position.z);
	}
}

void UpdateStepPositions(){
	Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
	ScriptParams@ params = hotspot_obj.GetScriptParams();
	quaternion hotspot_rotation = hotspot_obj.GetRotation();
	vec3 up_direction = normalize(hotspot_rotation * vec3(0.0, 1.0, 0.0));
	vec3 starting_position = hotspot_obj.GetTranslation() - up_direction * (hotspot_obj.GetScale().y * 2.0f - (params.GetFloat("Step size") / 2.0f));
	for(uint i = 0; i < steps.size(); i++){
		Object@ step = ReadObjectFromID(steps[i]);
		step.SetTranslation(starting_position + up_direction * i * current_step_size);
		step.SetRotation(hotspot_rotation);
	}
}

void AddStep(){
	Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
	ScriptParams@ params = hotspot_obj.GetScriptParams();
	string random_step_path = step_types[rand() % step_types.size()].path;
	int new_step_id = CreateObject(random_step_path);
	steps.insertLast(new_step_id);
}

void RemoveStep(){
	QueueDeleteObjectID(steps[steps.size() - 1]);
	steps.removeAt(steps.size() - 1);
}

void ClearSteps(){
	for(uint i = 0; i < steps.size(); i++){
		QueueDeleteObjectID(steps[i]);
	}
	steps.resize(0);
}

void HandleEvent(string event, MovementObject @mo) {
	if(event == "enter"){
		mo.ReceiveMessage("set_dialogue_control true");
		mo.ReceiveMessage("set_animation \"Data/Animations/r_sneakwalk.anm\"");
		vec3 current_position = mo.position;
		mo.ReceiveMessage("set_dialogue_position " + current_position.x + " " +  current_position.y + " " + current_position.z);
		users.insertLast(User(mo));
	}else if(event == "exit"){
		RemoveUser(mo);
	}
}

void RemoveUser(MovementObject@ mo){
	mo.ReceiveMessage("set_dialogue_control false");
	for(uint i = 0; i < users.size(); i++){
		if(users[i].id == mo.GetID()){
			users.removeAt(i);
			return;
		}
	}
}

void HandleEventItem(string event, ItemObject @obj) { }

void ReceiveMessage(string message) { }
