
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

array<StepType@> step_types = {		StepType("Data/Objects/ladder2_mid.xml")};

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

void HandleEvent(string event, MovementObject @mo) { }

void HandleEventItem(string event, ItemObject @obj) { }

void ReceiveMessage(string message) { }
