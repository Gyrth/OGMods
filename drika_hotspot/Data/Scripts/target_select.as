enum target_options {	id_option = (1<<0),
						reference_option = (1<<1),
						team_option = (1<<2),
						name_option = (1<<3),
						character_option = (1<<4)
					};

class TargetSelect{
	int object_id = -1;
	string reference_string = "drika_reference";
	string character_team = "team_drika";
	string object_name = "drika_object";

	identifier_types identifier_type;
	array<string> available_references;
	array<string> available_character_names;
	array<int> available_character_ids;
	int target_option;
	DrikaElement@ parent;

	TargetSelect(DrikaElement@ _parent){
		@parent = _parent;
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
				available_character_names.insertLast("Character id : " + char.GetID());
			}else{
				available_character_names.insertLast(char_obj.GetName());
			}

			available_character_ids.insertLast(char.GetID());
		}
	}

	void CheckAvailableTargets(){
		if((target_option & character_option) != 0){
			CheckCharactersAvailable();
		}
		if((target_option & reference_option) != 0){
			CheckReferenceAvailable();
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

		int current_identifier_type;

		for(uint i = 0; i < identifier_choices.size(); i++){
			if(	identifier_type == id && identifier_choices[i] == "ID"||
			 	identifier_type == team && identifier_choices[i] == "Team"||
				identifier_type == reference && identifier_choices[i] == "Reference"||
				identifier_type == character && identifier_choices[i] == "Character"||
				identifier_type == name && identifier_choices[i] == "Name"){
				current_identifier_type = i;
				break;
			}
		}

		if(ImGui_Combo("Identifier Type", current_identifier_type, identifier_choices, identifier_choices.size())){
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
			}
		}

		if(identifier_type == id){
			int new_object_id = object_id;
			if(ImGui_InputInt("Object ID", new_object_id)){
				parent.PreTargetChanged();
				object_id = new_object_id;
				parent.TargetChanged();
			}
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

			if(ImGui_Combo("Reference", current_reference, available_references, available_references.size())){
				parent.PreTargetChanged();
				reference_string = available_references[current_reference];
				parent.TargetChanged();
			}
		}else if(identifier_type == team){
			string new_character_team = character_team;
			if(ImGui_InputText("Team", new_character_team, 64)){
				parent.PreTargetChanged();
				character_team = new_character_team;
				parent.TargetChanged();
			}
		}else if(identifier_type == name){
			string new_object_name = object_name;
			if(ImGui_InputText("Name", new_object_name, 64)){
				parent.PreTargetChanged();
				object_name = new_object_name;
				parent.TargetChanged();
			}
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

			if(ImGui_Combo("Character", current_character, available_character_names, available_character_names.size())){
				parent.PreTargetChanged();
				object_id = available_character_ids[current_character];
				parent.TargetChanged();
			}
		}
	}

	void SaveIdentifier(JSONValue &inout data){
		data["identifier_type"] = JSONValue(identifier_type);
		if(identifier_type == id){
			data["identifier"] = JSONValue(object_id);
		}else if(identifier_type == reference){
			data["identifier"] = JSONValue(reference_string);
		}else if(identifier_type == team){
			data["identifier"] = JSONValue(character_team);
		}else if(identifier_type == name){
			data["identifier"] = JSONValue(object_name);
		}else if(identifier_type == character){
			data["identifier"] = JSONValue(object_id);
		}
	}

	void LoadIdentifier(JSONValue params){
		if(params.isMember("identifier_type")){
			if(params["identifier_type"].asInt() == id){
				identifier_type = identifier_types(id);
				object_id = params["identifier"].asInt();
			}else if(params["identifier_type"].asInt() == reference){
				identifier_type = identifier_types(reference);
				reference_string = params["identifier"].asString();
			}else if(params["identifier_type"].asInt() == team){
				identifier_type = identifier_types(team);
				character_team = params["identifier"].asString();
			}else if(params["identifier_type"].asInt() == name){
				identifier_type = identifier_types(name);
				object_name = params["identifier"].asString();
			}else if(params["identifier_type"].asInt() == character){
				identifier_type = identifier_types(character);
				object_id = params["identifier"].asInt();
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
			if(registered_object_id == -1){
				//Does not exist yet.
			}else{
				target_objects.insertLast(ReadObjectFromID(registered_object_id));
			}
		}else if (identifier_type == team){
			array<int> object_ids = GetObjectIDs();
			for(uint i = 0; i < object_ids.size(); i++){
				Object@ obj = ReadObjectFromID(object_ids[i]);
				ScriptParams@ obj_params = obj.GetScriptParams();
				if(obj_params.HasParam("Teams")){
					//Removed all the spaces.
					string no_spaces_param = join(obj_params.GetString("Teams").split(" "), "");
					//Teams are , seperated.
					array<string> teams = no_spaces_param.split(",");
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
		}
		return "NA";
	}

	void ClearTarget(){
		object_id = -1;
		reference_string = "drika_reference";
		character_team = "team_drika";
		object_name = "drika_object";
	}
}
