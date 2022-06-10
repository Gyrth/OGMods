bool is_editor_enabled = false;
string dialogue_name = "";
string dialogue_data = "";
string dialogue_string;
bool auto_start = false;
bool on_enter = false;
const int kObjectIdMaxCharacterCount = 10;

void LaunchCustomGUI() {
	is_editor_enabled = true;
}

void SetParameters(){
	params.AddString("dialogue_data", "");
	params.AddString("dialogue_name", "");
	params.AddIntCheckbox("auto_start", false);
	params.AddIntCheckbox("on_enter", false);

	dialogue_name = params.GetString("dialogue_name");
	dialogue_data = params.GetString("dialogue_data");
	auto_start = params.GetInt("auto_start") == 1;
	on_enter = params.GetInt("on_enter") == 1;
}

void HandleEvent(string event, MovementObject @mo){
	if(event == "enter"){
		OnEnter(mo);
	}
}

void SendDialogue(){
	array<string> split_data = dialogue_data.split("\n");
	split_data.reverse();

	for(uint i = 0; i < split_data.size(); i++){
		level.SendMessage(split_data[i]);
	}
}

void DrawEditor() {
	bool is_updated = false;

	int hotspot_id = hotspot.GetID();
	Object@ hotspot_obj = ReadObjectFromID(hotspot_id);
	DebugDrawBillboard(	"Data/Textures/ITEMS/item8BIT_skull.png",
						hotspot_obj.GetTranslation() + vec3(0.0, 0.5, 0.0),
						hotspot_obj.GetScale()[1] * 2.0,
						vec4(1.0),
						_delete_on_draw);

	DebugDrawText(hotspot_obj.GetTranslation() + vec3(0.0, 1.0, 0.0), dialogue_name, 1.0f, true, _delete_on_draw);

	if(is_editor_enabled){
		ImGui_PushStyleVar(ImGuiStyleVar_WindowMinSize, vec2(840, 440));
		ImGui_Begin("Therium Advance Dialogue Hotspot - id: " + hotspot_id, is_editor_enabled);

		if(ImGui_Checkbox("Auto Start", auto_start)){
			params.SetInt("auto_start", auto_start?1:0);
			is_updated = true;
		}

		if(ImGui_Checkbox("On Enter", on_enter)){
			params.SetInt("on_enter", on_enter?1:0);
			is_updated = true;
		}

		if(ImGui_InputText("Dialogue Name", dialogue_string, kObjectIdMaxCharacterCount + 1, ImGuiInputTextFlags_CharsNoBlank)){
			params.SetString("dialogue_name", dialogue_string);
			is_updated = true;
		}

		if(ImGui_InputTextMultiline("Dialogue", dialogue_data, 128)){
			params.SetString("dialogue_data", dialogue_data);
			is_updated = true;
		}

		ImGui_End();
		ImGui_PopStyleVar();
	}

	if(is_updated) {
		SetParameters();
	}
}

void Reset(){
	if(auto_start){
		SendDialogue();
	}
}

void OnEnter(MovementObject @mo){
	if(on_enter){
		SendDialogue();
	}
}
