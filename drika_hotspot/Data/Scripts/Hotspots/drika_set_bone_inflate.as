class DrikaSetBoneInflate : DrikaElement{
	string bone_name;
	float inflate_value;

	DrikaSetBoneInflate(JSONValue params = JSONValue()){
		bone_name = GetJSONString(params, "bone_name", "torso");
		inflate_value = GetJSONFloat(params, "inflate_value", 0.0);
		InterpIdentifier(params);

		connection_types = {_movement_object};
		drika_element_type = drika_set_bone_inflate;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("set_bone_inflate");
		data["bone_name"] = JSONValue(bone_name);
		data["inflate_value"] = JSONValue(inflate_value);
		data["identifier_type"] = JSONValue(identifier_type);
		if(identifier_type == id){
			data["identifier"] = JSONValue(object_id);
		}else if(identifier_type == reference){
			data["identifier"] = JSONValue(reference_string);
		}else if(identifier_type == team){
			data["identifier"] = JSONValue(character_team);
		}
		return data;
	}

	void PostInit(){
		Object@ target_object = GetTargetObject();
		if(target_object is null){
			Log(warning, "MovementObject does not exist with id " + object_id);
			return;
		}
	}

	void Delete(){
		if(triggered){
			SetBoneInflate(true);
		}
	}

	string GetDisplayString(){
		return "SetBoneInflate " + bone_name + " " + inflate_value;
	}

	void StartSettings(){
		CheckReferenceAvailable();
	}

	void ApplySettings(){
		//Reset the morph value set by the preview.
		SetBoneInflate(true);
	}

	void DrawSettings(){
		DrawSelectTargetUI();
		if(ImGui_InputText("Bone Name", bone_name, 64)){
			SetBoneInflate(false);
		}
		if(ImGui_IsItemHovered()){
			ImGui_PushStyleColor(ImGuiCol_PopupBg, titlebar_color);
			ImGui_SetTooltip("Possible bone names:\nrightear\nleftear\nrightarm\nleftarm\nhead\ntorso\ntail\nright_leg\nleft_leg\nlefthand\nrighthand\nleftfingers\nrightfingers\nleftthumb\nrightthumb");
			ImGui_PopStyleColor();
		}

		if(ImGui_SliderFloat("Value", inflate_value, 0.0f, 1.0f, "%.2f")){
			SetBoneInflate(false);
		}
	}

	bool Trigger(){
		MovementObject@ target_character = GetTargetMovementObject();
		if(target_character is null){
			return false;
		}
		triggered = true;
		SetBoneInflate(false);
		return true;
	}

	void DrawEditing(){
		MovementObject@ target_character = GetTargetMovementObject();
		if(target_character is null){
			return;
		}
		DebugDrawLine(target_character.position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
	}

	void SetBoneInflate(bool reset){
		MovementObject@ target_character = GetTargetMovementObject();
		if(target_character is null){
			return;
		}
		if(!target_character.rigged_object().skeleton().IKBoneExists(bone_name)) {
			return;
		}

		int bone = target_character.rigged_object().skeleton().IKBoneStart(bone_name);
		int chain_len = target_character.rigged_object().skeleton().IKBoneLength(bone_name);

		for(int i = 0; i < chain_len; ++i) {
			target_character.rigged_object().skeleton().SetBoneInflate(bone, reset?1.0f:inflate_value);
			bone = target_character.rigged_object().skeleton().GetParent(bone);

			if(bone == -1) {
				break;
			}
		}
	}

	void Reset(){
		if(triggered){
			triggered = false;
			SetBoneInflate(true);
		}
	}
}
