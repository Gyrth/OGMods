enum target_options {	id_option = (1<<0),
						reference_option = (1<<1),
						team_option = (1<<2),
						name_option = (1<<3),
						character_option = (1<<4),
						item_option = (1<<5),
						batch_option = (1<<6)
					};

class BatchObject{
	string text;
	vec4 color;
	int id;

	BatchObject(int _id, string _text, vec4 _color){
		text = _text;
		color = _color;
		id = _id;
	}
}

/* vec4(156, 255, 159, 255),
vec4(153, 255, 193, 255),
vec4(255, 0, 255, 255),
vec4(0, 149, 255, 255), */

vec4 GetBatchObjectColor(int object_type){
	switch(object_type){
		case _env_object:
			return vec4(230, 184, 175, 255);
		case _movement_object:
			return vec4(255, 153, 0, 255);
		case _spawn_point:
			return vec4(0, 243, 255, 255);
		case _decal_object:
			return vec4(0, 173, 182, 255);
		case _hotspot_object:
			return vec4(0, 255, 0, 255);
		case _group:
			return vec4(0, 255, 149, 255);
		case _item_object:
			return vec4(255, 255, 0, 255);
		case _path_point_object:
			return vec4(255, 0, 0, 255);
		case _ambient_sound_object:
			return vec4(150, 0, 0, 255);
		case _placeholder_object:
			return vec4(221, 126, 107, 255);
		case _light_probe_object:
			return vec4(150, 0, 150, 255);
		case _dynamic_light_object:
			return vec4(0, 113, 194, 255);
		case _navmesh_hint_object:
			return vec4(0, 43, 255, 255);
		case _navmesh_region_object:
			return vec4(126, 139, 226, 255);
		case _navmesh_connection_object:
			return vec4(0, 182, 0, 255);
		case _reflection_capture_object:
			return vec4(162, 250, 255, 255);
		case _light_volume_object:
			return vec4(203, 200, 255, 255);
		case _prefab:
			return vec4(0, 173, 101, 255);
		default :
			break;
	}
	return vec4(1.0);
}

string GetObjectTypeString(int object_type){
	switch(object_type){
		case _env_object:
			return "EnvObject";
		case _movement_object:
			return "MovementObject";
		case _spawn_point:
			return "SpawnPoint";
		case _decal_object:
			return "DecalObject";
		case _hotspot_object:
			return "Hotspot";
		case _group:
			return "Group";
		case _item_object:
			return "ItemObject";
		case _path_point_object:
			return "PathPointObject";
		case _ambient_sound_object:
			return "AmbientSound";
		case _placeholder_object:
			return "Placeholder";
		case _light_probe_object:
			return "LightProbe";
		case _dynamic_light_object:
			return "DynamicLight";
		case _navmesh_hint_object:
			return "NavMeshHint";
		case _navmesh_region_object:
			return "NavMeshRegion";
		case _navmesh_connection_object:
			return "NavMeshConnection";
		case _reflection_capture_object:
			return "ReflectionCapture";
		case _light_volume_object:
			return "LightVolume";
		case _prefab:
			return "Prefab";
		default :
			break;
	}
	return "NA";
}

class DrikaTargetSelect{
	int object_id = -1;
	string reference_string = "drika_reference";
	string character_team = "team_drika";
	string object_name = "drika_object";

	string identifier_type_tag = "identifier_type";
	string identifier_tag = "identifier";
	string tag = "";

	identifier_types identifier_type;
	array<string> available_references;
	array<string> available_character_names;
	array<int> available_character_ids;
	array<string> available_item_names;
	array<int> available_item_ids;
	array<int> batch_ids;
	int target_option;
	DrikaElement@ parent;
	array<BatchObject@> batch_objects;

	DrikaTargetSelect(DrikaElement@ _parent, string tag = ""){
		@parent = _parent;
		if(tag != ""){
			this.tag = tag;
			identifier_type_tag = "identifier_type_" + tag;
			identifier_tag = "identifier_" + tag;
		}
	}

	bool ConnectTo(Object @other){
		if(other.GetID() == object_id){
			return false;
		}
		if(object_id != -1 && ObjectExists(object_id)){
			parent.PreTargetChanged();
			Disconnect(ReadObjectFromID(object_id));
		}
		object_id = other.GetID();
		parent.TargetChanged();
		return false;
	}

	bool Disconnect(Object @other){
		if(other.GetID() == object_id){
			object_id = -1;
			return false;
		}
		return false;
	}

	void CheckCharactersAvailable(){
		available_character_ids.resize(0);
		available_character_names.resize(0);

		for(int i = 0; i < GetNumCharacters(); i++){
			MovementObject@ char = ReadCharacter(i);
			Object@ char_obj = ReadObjectFromID(char.GetID());

			if(char_obj.GetName() == ""){
				available_character_names.insertLast("Character id " + char.GetID());
			}else{
				available_character_names.insertLast(char_obj.GetName());
			}

			available_character_ids.insertLast(char.GetID());
		}
	}

	void CheckItemsAvailable(){
		available_item_ids.resize(0);
		available_item_names.resize(0);

		for(int i = 0; i < GetNumItems(); i++){
			ItemObject@ item = ReadItem(i);

			if(item.GetLabel() == ""){
				available_item_names.insertLast("Item " + item.GetID());
			}else{
				available_item_names.insertLast(item.GetLabel() + " " + item.GetID());
			}

			available_item_ids.insertLast(item.GetID());
		}
	}

	void CheckAvailableTargets(){
		if((target_option & character_option) != 0){
			CheckCharactersAvailable();
		}
		if((target_option & reference_option) != 0){
			CheckReferenceAvailable();
		}
		if((target_option & item_option) != 0){
			CheckItemsAvailable();
		}
		if((target_option & batch_option) != 0){
			CheckBatchObjects();
		}
	}

	void CheckBatchObjects(){
		if(batch_objects.size() == 0){
			for(uint i = 0; i < batch_ids.size(); i++){
				AddBatchObject(batch_ids[i]);
			}
		}
	}

	void CheckReferenceAvailable(){
		available_references = GetReferences();
	}

	void DrawSelectTargetUI(){
		array<string> identifier_choices = {};

		if((target_option & id_option) != 0){
			identifier_choices.insertLast("ID");
		}

		if((target_option & character_option) != 0){
			identifier_choices.insertLast("Character");
		}

		if((target_option & reference_option) != 0 && available_references.size() > 0){
			identifier_choices.insertLast("Reference");
		}

		if((target_option & team_option) != 0){
			identifier_choices.insertLast("Team");
		}

		if((target_option & name_option) != 0){
			identifier_choices.insertLast("Name");
		}

		if((target_option & item_option) != 0 && available_item_ids.size() > 0){
			identifier_choices.insertLast("Item");
		}

		if((target_option & batch_option) != 0){
			identifier_choices.insertLast("Batch");
		}

		int current_identifier_type = -1;

		for(uint i = 0; i < identifier_choices.size(); i++){
			if(	identifier_type == id && identifier_choices[i] == "ID"||
			 	identifier_type == team && identifier_choices[i] == "Team"||
				identifier_type == reference && identifier_choices[i] == "Reference"||
				identifier_type == character && identifier_choices[i] == "Character"||
				identifier_type == item && identifier_choices[i] == "Item"||
				identifier_type == batch && identifier_choices[i] == "Batch"||
				identifier_type == name && identifier_choices[i] == "Name"){
				current_identifier_type = i;
				break;
			}
		}

		bool refresh_target = false;
		bool target_changed = false;
		if(current_identifier_type == -1){
			current_identifier_type = 0;
			refresh_target = true;
		}

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Identifier Type");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_PushItemWidth(second_column_width);

		if(ImGui_Combo("##Identifier Type" + tag, current_identifier_type, identifier_choices, identifier_choices.size()) || refresh_target){
			parent.PreTargetChanged();
			if(identifier_choices[current_identifier_type] == "ID"){
				identifier_type = id;
			}else if(identifier_choices[current_identifier_type] == "Team"){
				identifier_type = team;
			}else if(identifier_choices[current_identifier_type] == "Reference"){
				identifier_type = reference;
			}else if(identifier_choices[current_identifier_type] == "Name"){
				identifier_type = name;
			}else if(identifier_choices[current_identifier_type] == "Character"){
				identifier_type = character;
			}else if(identifier_choices[current_identifier_type] == "Item"){
				identifier_type = item;
			}else if(identifier_choices[current_identifier_type] == "Batch"){
				identifier_type = batch;
			}
			target_changed = true;
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		if(identifier_type == id){
			int new_object_id = object_id;
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Object ID");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_InputInt("##Object ID" + tag, new_object_id)){
				parent.PreTargetChanged();
				object_id = new_object_id;
				parent.TargetChanged();
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else if(identifier_type == reference){
			int current_reference = -1;

			if(available_references.size() > 0){
				//Find the index of the chosen reference or set the default to the first one.
				current_reference = 0;
				for(uint i = 0; i < available_references.size(); i++){
					if(available_references[i] == reference_string){
						current_reference = i;
						break;
					}
				}
			}else{
				//Force the identifier type to id when no references are available.
				identifier_type = id;
				return;
			}

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Reference");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_Combo("##Reference" + tag, current_reference, available_references, available_references.size())){
				parent.PreTargetChanged();
				reference_string = available_references[current_reference];
				parent.TargetChanged();
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else if(identifier_type == team){
			string new_character_team = character_team;

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Team");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_InputText("##Team" + tag, new_character_team, 64)){
				parent.PreTargetChanged();
				character_team = new_character_team;
				parent.TargetChanged();
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else if(identifier_type == name){
			string new_object_name = object_name;

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Name");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_InputText("##Name" + tag, new_object_name, 64)){
				parent.PreTargetChanged();
				object_name = new_object_name;
				parent.TargetChanged();
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else if(identifier_type == character){
			int current_character = -1;
			for(uint i = 0; i < available_character_ids.size(); i++){
				if(object_id == available_character_ids[i]){
					current_character = i;
					break;
				}
			}

			//Pick the first character if the object_id can't be found.
			if(current_character == -1 && available_character_ids.size() > 0){
				current_character = 0;
				object_id = available_character_ids[0];
			}

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Character");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_Combo("##Character" + tag, current_character, available_character_names, available_character_names.size())){
				parent.PreTargetChanged();
				object_id = available_character_ids[current_character];
				parent.TargetChanged();
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else if(identifier_type == item){
			int current_item = -1;
			for(uint i = 0; i < available_item_ids.size(); i++){
				if(object_id == available_item_ids[i]){
					current_item = i;
					break;
				}
			}

			//Pick the first item if the object_id can't be found.
			if(current_item == -1 && available_item_ids.size() > 0){
				Log(warning, "Object item does not exist " + object_id);
				current_item = 0;
				object_id = available_item_ids[0];
				Log(warning, "Setting to " + object_id);
			}

			ImGui_AlignTextToFramePadding();
			ImGui_Text("Item");
			ImGui_NextColumn();
			ImGui_PushItemWidth(second_column_width);
			if(ImGui_Combo("##Item" + tag, current_item, available_item_names, available_item_names.size())){
				parent.PreTargetChanged();
				object_id = available_item_ids[current_item];
				parent.TargetChanged();
			}
			ImGui_PopItemWidth();
			ImGui_NextColumn();
		}else if(identifier_type == batch){
			ImGui_AlignTextToFramePadding();
			ImGui_Text("Batch");
			ImGui_NextColumn();

			ImGui_BeginChild("batch_select_ui" + tag, vec2(0, 200), false, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoScrollbar);

			if(ImGui_Button("Add Selected")){
				array<int> object_ids = GetSelected();
				for(uint i = 0; i < object_ids.size(); i++){
					Object@ obj = ReadObjectFromID(object_ids[i]);
					if(batch_ids.find(object_ids[i]) == -1){
						batch_ids.insertLast(object_ids[i]);
						AddBatchObject(obj.GetID());
					}
				}
			}
			ImGui_SameLine();
			if(ImGui_Button("Remove Selected")){
				array<int> object_ids = GetSelected();
				for(uint i = 0; i < object_ids.size(); i++){
					Object@ obj = ReadObjectFromID(object_ids[i]);
					int batch_id_index = batch_ids.find(object_ids[i]);
					if(batch_id_index != -1){
						batch_ids.removeAt(batch_id_index);
					}

					for(uint j = 0; j < batch_objects.size(); j++){
						if(batch_objects[j].id == object_ids[i]){
							batch_objects.removeAt(j);
						}
					}
				}
			}
			ImGui_SameLine();
			if(ImGui_Button("Clear")){
				batch_ids.resize(0);
				batch_objects.resize(0);
			}

			if(ImGui_BeginChildFrame(123, vec2(-1, 200), ImGuiWindowFlags_AlwaysAutoResize)){

				for(uint i = 0; i < batch_objects.size(); i++){
					/* ImGui_PushID("delete" + i); */
					if(ImGui_Button("Delete " + batch_objects[i].id)){
					/* if(ImGui_ImageButton(delete_icon, vec2(10), vec2(0), vec2(1), 2, vec4(0))){ */
						Object@ obj = ReadObjectFromID(batch_objects[i].id);
						int batch_id_index = batch_ids.find(batch_objects[i].id);
						if(batch_id_index != -1){
							batch_ids.removeAt(batch_id_index);
						}
						batch_objects.removeAt(i);
						continue;
					}
					/* ImGui_PopID(); */
					ImGui_SameLine();

					vec4 text_color = batch_objects[i].color;
					ImGui_PushStyleColor(ImGuiCol_Text, text_color);
					ImGui_PushItemWidth(150.0);
					if(ImGui_Selectable(batch_objects[i].text, false)){

					}
					ImGui_PopItemWidth();
					ImGui_PopStyleColor();
				}

				ImGui_EndChildFrame();
			}
			ImGui_EndChild();
			ImGui_NextColumn();
		}

		if(target_changed){
			parent.TargetChanged();
		}
	}

	void AddBatchObject(int batch_object_id){
		Object@ obj = ReadObjectFromID(batch_object_id);
		string label = obj.GetLabel();
		string editor_label = obj.GetEditorLabel();
		string name = obj.GetName();
		string type_string = GetObjectTypeString(obj.GetType());

		string text = obj.GetID() + " ";
		text += (label != "")?label + " ":"";
		text += (editor_label != "")?editor_label + " ":"";
		text += (name != "")?name + " ":"";
		text += type_string;
		batch_objects.insertLast(BatchObject(obj.GetID(), text, GetBatchObjectColor(obj.GetType())));
	}

	void SaveIdentifier(JSONValue &inout data){
		data[identifier_type_tag] = JSONValue(identifier_type);
		if(identifier_type == id){
			data[identifier_tag] = JSONValue(object_id);
		}else if(identifier_type == reference){
			data[identifier_tag] = JSONValue(reference_string);
		}else if(identifier_type == team){
			data[identifier_tag] = JSONValue(character_team);
		}else if(identifier_type == name){
			data[identifier_tag] = JSONValue(object_name);
		}else if(identifier_type == character){
			data[identifier_tag] = JSONValue(object_id);
		}else if(identifier_type == item){
			data[identifier_tag] = JSONValue(object_id);
		}else if(identifier_type == batch){
			data[identifier_tag] = JSONValue(JSONarrayValue);
			for(uint i = 0; i < batch_ids.size(); i++){
				data[identifier_tag].append(batch_ids[i]);
			}
		}
	}

	void LoadIdentifier(JSONValue params){
		if(params.isMember(identifier_type_tag)){
			if(params[identifier_type_tag].asInt() == id){
				identifier_type = identifier_types(id);
				object_id = params[identifier_tag].asInt();
			}else if(params[identifier_type_tag].asInt() == reference){
				identifier_type = identifier_types(reference);
				reference_string = params[identifier_tag].asString();
			}else if(params[identifier_type_tag].asInt() == team){
				identifier_type = identifier_types(team);
				character_team = params[identifier_tag].asString();
			}else if(params[identifier_type_tag].asInt() == name){
				identifier_type = identifier_types(name);
				object_name = params[identifier_tag].asString();
			}else if(params[identifier_type_tag].asInt() == character){
				identifier_type = identifier_types(character);
				object_id = params[identifier_tag].asInt();
			}else if(params[identifier_type_tag].asInt() == item){
				identifier_type = identifier_types(item);
				object_id = params[identifier_tag].asInt();
			}else if(params[identifier_type_tag].asInt() == batch){
				identifier_type = identifier_types(batch);
				batch_ids = GetJSONIntArray(params, identifier_tag, {});
			}
		}else{
			//By default the id is used as identifier with -1 as the target id.
			identifier_type = identifier_types(id);
		}
	}

	array<Object@> GetTargetObjects(){
		array<Object@> target_objects;
		if(identifier_type == id){
			if(object_id == -1){
				//Do nothing.
			}else if(!ObjectExists(object_id)){
				Log(warning, "The object with id " + object_id + " doesn't exist anymore, so resetting to -1.");
				object_id = -1;
			}else{
				target_objects.insertLast(ReadObjectFromID(object_id));
			}
		}else if (identifier_type == reference){
			int registered_object_id = GetRegisteredObjectID(reference_string);
			if(registered_object_id == -1 || !ObjectExists(registered_object_id)){
				//Does not exist yet.
			}else{
				target_objects.insertLast(ReadObjectFromID(registered_object_id));
			}
		}else if (identifier_type == team){
			array<int> object_ids = GetObjectIDsType(_movement_object);
			for(uint i = 0; i < object_ids.size(); i++){
				Object@ obj = ReadObjectFromID(object_ids[i]);
				ScriptParams@ obj_params = obj.GetScriptParams();

				if(obj_params.HasParam("Teams")){
					array<string> teams;
					//Teams are , seperated or space comma.
					array<string> space_comma_separated = obj_params.GetString("Teams").split(", ");
					for(uint j = 0; j < space_comma_separated.size(); j++){
						array<string> comma_separated = space_comma_separated[j].split(",");
						teams.insertAt(0, comma_separated);
					}

					if(teams.find(character_team) != -1){
						target_objects.insertLast(obj);
					}
				}
			}
		}else if (identifier_type == name){
			array<int> object_ids = GetObjectIDs();
			for(uint i = 0; i < object_ids.size(); i++){
				Object@ obj = ReadObjectFromID(object_ids[i]);
				if(obj.GetName() == object_name){
					target_objects.insertLast(obj);
				}
			}
		}else if(identifier_type == character){
			if(object_id == -1){
				//Do nothing.
			}else if(!ObjectExists(object_id)){
				Log(warning, "The object with id " + object_id + " doesn't exist anymore, so resetting to -1.");
				object_id = -1;
			}else{
				target_objects.insertLast(ReadObjectFromID(object_id));
			}
		}else if(identifier_type == item){
			if(object_id == -1){
				//Do nothing.
			}else if(!ObjectExists(object_id)){
				Log(warning, "The object with id " + object_id + " doesn't exist anymore, so resetting to -1.");
				object_id = -1;
			}else{
				target_objects.insertLast(ReadObjectFromID(object_id));
			}
		}else if(identifier_type == batch){
			for(uint i = 0; i < batch_ids.size(); i++){
				target_objects.insertLast(ReadObjectFromID(batch_ids[i]));
			}
		}
		return target_objects;
	}

	array<MovementObject@> GetTargetMovementObjects(){
		array<MovementObject@> target_movement_objects;
		if(identifier_type == id){
			if(object_id == -1){
				//Do nothing.
			}else if(!MovementObjectExists(object_id)){
				Log(warning, "The MovementObject with id " + object_id + " doesn't exist or is not a MovementObject, so resetting to -1.");
				object_id = -1;
			}else{
				target_movement_objects.insertLast(ReadCharacterID(object_id));
			}
		}else if (identifier_type == reference){
			int registered_object_id = GetRegisteredObjectID(reference_string);
			if(registered_object_id == -1){
				//Does not exist yet.
			}else if(MovementObjectExists(registered_object_id)){
				target_movement_objects.insertLast(ReadCharacterID(registered_object_id));
			}
		}else if (identifier_type == team){
			array<int> mo_ids = GetObjectIDsType(_movement_object);
			for(uint i = 0; i < mo_ids.size(); i++){
				MovementObject@ mo = ReadCharacterID(mo_ids[i]);
				Object@ obj = ReadObjectFromID(mo_ids[i]);
				ScriptParams@ obj_params = obj.GetScriptParams();
				if(obj_params.HasParam("Teams")){
					//Removed all the spaces.
					string no_spaces_param = join(obj_params.GetString("Teams").split(" "), "");
					//Teams are , seperated.
					array<string> teams = no_spaces_param.split(",");
					if(teams.find(character_team) != -1){
						target_movement_objects.insertLast(mo);
					}
				}
			}
		}else if (identifier_type == name){
			array<int> mo_ids = GetObjectIDsType(_movement_object);
			for(uint i = 0; i < mo_ids.size(); i++){
				Object@ obj = ReadObjectFromID(mo_ids[i]);
				MovementObject@ mo = ReadCharacterID(mo_ids[i]);
				if(obj.GetName() == object_name){
					target_movement_objects.insertLast(mo);
				}
			}
		}else if(identifier_type == character){
			if(object_id == -1){
				//Do nothing.
			}else if(!MovementObjectExists(object_id)){
				Log(warning, "The MovementObject with id " + object_id + " doesn't exist or is not a MovementObject, so resetting to -1.");
				object_id = -1;
			}else{
				target_movement_objects.insertLast(ReadCharacterID(object_id));
			}
		}else if(identifier_type == batch){
			for(uint i = 0; i < batch_ids.size(); i++){
				if(!MovementObjectExists(batch_ids[i])){
					target_movement_objects.insertLast(ReadCharacterID(batch_ids[i]));
				}
			}
		}
		return target_movement_objects;
	}

	string GetTargetDisplayText(){
		if(identifier_type == id){
			return "" + object_id;
		}else if (identifier_type == reference){
			return reference_string;
		}else if (identifier_type == team){
			return character_team;
		}else if (identifier_type == name){
			return object_name;
		}else if(identifier_type == character){
			if(object_id != -1){
				if(ObjectExists(object_id)){
					Object@ char_obj = ReadObjectFromID(object_id);

					if(char_obj.GetName() != ""){
						return char_obj.GetName();
					}else{
						return char_obj.GetID() + "";
					}
				}
			}
		}else if(identifier_type == item){
			if(object_id != -1){
				if(ObjectExists(object_id)){
					ItemObject@ item_obj = ReadItemID(object_id);

					if(item_obj.GetLabel() != ""){
						return item_obj.GetLabel();
					}else{
						return item_obj.GetID() + "";
					}
				}
			}
		}else if (identifier_type == batch){
			return "batch";
		}
		return "NA";
	}

	void ClearTarget(){
		object_id = -1;
		reference_string = "drika_reference";
		character_team = "team_drika";
		object_name = "drika_object";
	}

	void SetSelected(bool selected){
		array<Object@> target_objects = GetTargetObjects();
		for(uint i = 0 ; i < target_objects.size(); i++){
			target_objects[i].SetSelected(selected);
		}
	}
}
