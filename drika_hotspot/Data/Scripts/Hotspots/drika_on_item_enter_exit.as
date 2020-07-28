class DrikaOnItemEnterExit : DrikaElement{
	hotspot_trigger_types hotspot_trigger_type;
	int new_hotspot_trigger_type;
	array<int> items_inside;

	DrikaOnItemEnterExit(JSONValue params = JSONValue()){
		hotspot_trigger_type = hotspot_trigger_types(GetJSONInt(params, "hotspot_trigger_type", 0));
		new_hotspot_trigger_type = hotspot_trigger_type;

		@target_select = DrikaTargetSelect(this, params);
		target_select.target_option = id_option | name_option | item_option | reference_option;

		connection_types = {_item_object};
		drika_element_type = drika_on_item_enter_exit;
		has_settings = true;
	}

	void PostInit(){
		target_select.PostInit();
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["hotspot_trigger_type"] = JSONValue(hotspot_trigger_type);
		target_select.SaveIdentifier(data);
		return data;
	}

	string GetDisplayString(){
		string display_string = "";

		if(hotspot_trigger_type == on_enter){
			display_string += "OnItemEnter ";
		}else if(hotspot_trigger_type == on_exit){
			display_string += "OnItemExit ";
		}else if(hotspot_trigger_type == while_inside){
			display_string += "WhileItemInside ";
		}else if(hotspot_trigger_type == while_outside){
			display_string += "WhileItemOutside ";
		}

		display_string += target_select.GetTargetDisplayText();

		return display_string;
	}

	void StartSettings(){
		target_select.CheckAvailableTargets();
	}

	void DrawSettings(){
		float option_name_width = 120.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Check for");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_PushItemWidth(second_column_width);
		if(ImGui_Combo("##Check for", new_hotspot_trigger_type, hotspot_trigger_choices, hotspot_trigger_choices.size())){
			hotspot_trigger_type = hotspot_trigger_types(new_hotspot_trigger_type);
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		target_select.DrawSelectTargetUI();
	}

	void DrawEditing(){
		array<Object@> targets = target_select.GetTargetObjects();
		for(uint i = 0; i < targets.size(); i++){
			if(targets[i].GetType() == _item_object){
				DebugDrawLine(targets[i].GetTranslation(), this_hotspot.GetTranslation(), vec3(0.0, 1.0, 0.0), _delete_on_update);
			}
		}
	}

	bool Trigger(){
		if(!triggered){
			items_inside = GetItemsInside();
		}
		array<Object@> objects = target_select.GetTargetObjects();

		if(hotspot_trigger_type == on_enter){
			array<int> new_items_inside = GetItemsInside();
			for(uint i = 0; i < objects.size(); i++){
				int obj_id = objects[i].GetID();
				if(items_inside.find(obj_id) == -1 && new_items_inside.find(obj_id) != -1){
					triggered = false;
					return true;
				}
			}
			items_inside = new_items_inside;
		}else if(hotspot_trigger_type == on_exit){
			array<int> new_items_inside = GetItemsInside();
			for(uint i = 0; i < objects.size(); i++){
				int obj_id = objects[i].GetID();
				if(items_inside.find(obj_id) != -1 && new_items_inside.find(obj_id) == -1){
					triggered = false;
					return true;
				}
			}
			items_inside = new_items_inside;
		}else if(hotspot_trigger_type == while_inside){
			for(uint i = 0; i < objects.size(); i++){
				if(items_inside.find(objects[i].GetID()) != -1){
					triggered = false;
					return true;
				}
			}
		}else if(hotspot_trigger_type == while_outside){
			for(uint i = 0; i < objects.size(); i++){
				if(items_inside.find(objects[i].GetID()) == -1){
					triggered = false;
					return true;
				}
			}
		}
		items_inside = GetItemsInside();
		triggered = true;
		return false;
	}

	array<int> GetItemsInside(){
		array<int> object_ids = GetObjectIDsType(_item_object);
		mat4 hotspot_transform = this_hotspot.GetTransform();
		array<int> inside_ids;

		for(uint i = 0; i < object_ids.size(); i++){
			ItemObject@ io = ReadItemID(object_ids[i]);

			vec3 io_translation = io.GetPhysicsPosition();
			vec3 local_space_translation = invert(hotspot_transform) * io_translation;

			if(local_space_translation.x >= -2 && local_space_translation.x <= 2 &&
				local_space_translation.y >= -2 && local_space_translation.y <= 2 &&
				local_space_translation.z >= -2 && local_space_translation.z <= 2){
				inside_ids.insertLast(object_ids[i]);
			}
		}
		return inside_ids;
	}

	void Reset(){
		triggered = false;
	}

	void Delete(){
		target_select.Delete();
	}
}
