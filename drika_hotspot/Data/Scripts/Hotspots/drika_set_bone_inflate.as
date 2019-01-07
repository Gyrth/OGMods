class DrikaSetBoneInflate : DrikaElement{
	string bone_name;
	float inflate_value;

	DrikaSetBoneInflate(JSONValue params = JSONValue()){
		bone_name = GetJSONString(params, "bone_name", "torso");
		inflate_value = GetJSONFloat(params, "inflate_value", 0.0);
		LoadIdentifier(params);

		connection_types = {_movement_object};
		drika_element_type = drika_set_bone_inflate;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("set_bone_inflate");
		data["bone_name"] = JSONValue(bone_name);
		data["inflate_value"] = JSONValue(inflate_value);
		SaveIdentifier(data);
		return data;
	}

	void Delete(){
		if(triggered){
			SetBoneInflate(true);
		}
	}

	string GetDisplayString(){
		return "SetBoneInflate " + GetTargetDisplayText() + " " + bone_name + " " + inflate_value;
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
		triggered = true;
		return SetBoneInflate(false);
	}

	void DrawEditing(){
		array<MovementObject@> targets = GetTargetMovementObjects();
		for(uint i = 0; i < targets.size(); i++){
			DebugDrawLine(targets[i].position, this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
		}
	}

	bool SetBoneInflate(bool reset){
		array<MovementObject@> targets = GetTargetMovementObjects();
		if(targets.size() == 0){return false;}
		for(uint i = 0; i < targets.size(); i++){
			if(!targets[i].rigged_object().skeleton().IKBoneExists(bone_name)){
				continue;
			}

			int bone = targets[i].rigged_object().skeleton().IKBoneStart(bone_name);
			int chain_len = targets[i].rigged_object().skeleton().IKBoneLength(bone_name);

			for(int j = 0; j < chain_len; ++j){
				targets[i].rigged_object().skeleton().SetBoneInflate(bone, reset?1.0f:inflate_value);
				bone = targets[i].rigged_object().skeleton().GetParent(bone);

				if(bone == -1){
					break;
				}
			}
		}
		return true;
	}

	void Reset(){
		if(triggered){
			triggered = false;
			SetBoneInflate(true);
		}
	}
}
