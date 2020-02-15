enum target_options {	id_option = (1<<0),
						reference_option = (1<<1),
						team_option = (1<<2),
						name_option = (1<<3),
						character_option = (1<<4),
						item_option = (1<<5)
					};

class TargetSelect{
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
	int target_option;
	DrikaElement@ parent;

	TargetSelect(DrikaElement@ _parent, string tag = ""){
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

		int current_identifier_type = -1;

		for(uint i = 0; i < identifier_choices.size(); i++){
			if(	identifier_type == id && identifier_choices[i] == "ID"||
			 	identifier_type == team && identifier_choices[i] == "Team"||
				identifier_type == reference && identifier_choices[i] == "Reference"||
				identifier_type == character && identifier_choices[i] == "Character"||
				identifier_type == item && identifier_choices[i] == "Item"||
				identifier_type == name && identifier_choices[i] == "Name"){
				current_identifier_type = i;
				break;
			}
		}

		bool refresh_target = false;
		if(current_identifier_type == -1){
			current_identifier_type = 0;
			refresh_target = true;
		}

		ImGui_Text("Identifier Type");
		ImGui_SameLine();
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
			}
			parent.TargetChanged();
		}

		if(identifier_type == id){
			int new_object_id = object_id;
			ImGui_Text("Object ID");
			ImGui_SameLine();
			if(ImGui_InputInt("##Object ID" + tag, new_object_id)){
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

			ImGui_Text("Reference");
			ImGui_SameLine();
			if(ImGui_Combo("##Reference" + tag, current_reference, available_references, available_references.size())){
				parent.PreTargetChanged();
				reference_string = available_references[current_reference];
				parent.TargetChanged();
			}
		}else if(identifier_type == team){
			string new_character_team = character_team;

			ImGui_Text("Team");
			ImGui_SameLine();
			if(ImGui_InputText("##Team" + tag, new_character_team, 64)){
				parent.PreTargetChanged();
				character_team = new_character_team;
				parent.TargetChanged();
			}
		}else if(identifier_type == name){
			string new_object_name = object_name;

			ImGui_Text("Name");
			ImGui_SameLine();
			if(ImGui_InputText("##Name" + tag, new_object_name, 64)){
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

			ImGui_Text("Character");
			ImGui_SameLine();
			if(ImGui_Combo("##Character" + tag, current_character, available_character_names, available_character_names.size())){
				parent.PreTargetChanged();
				object_id = available_character_ids[current_character];
				parent.TargetChanged();
			}
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

			ImGui_Text("Item");
			ImGui_SameLine();
			if(ImGui_Combo("##Item" + tag, current_item, available_item_names, available_item_names.size())){
				parent.PreTargetChanged();
				object_id = available_item_ids[current_item];
				parent.TargetChanged();
			}
		}
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
		}else if(identifier_type == item){
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
