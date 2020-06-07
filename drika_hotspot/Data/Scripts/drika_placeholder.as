class DrikaPlaceholder{
	int id = -1;
	Object@ object;
	PlaceholderObject@ placeholder;
	Object@ placeholder_object;
	string name;
	vec3 default_scale = vec3(0.25);
	string path = "Data/Objects/drika_hotspot_cube.xml";
	string object_path;
	DrikaElement@ parent;

	DrikaPlaceholder(){

	}

	void Save(JSONValue &inout data){
		if(Exists()){
			data["placeholder_id"] = JSONValue(id);
		}
	}

	void Load(JSONValue params){
		if(params.isMember("placeholder_id")){
			id = params["placeholder_id"].asInt();
		}
	}

	void Create(){
		id = CreateObject(path, false);
		@object = ReadObjectFromID(id);
		object.SetName(name);
		object.SetSelectable(true);
		object.SetTranslatable(true);
		object.SetScalable(true);
		object.SetRotatable(true);

		object.SetDeletable(false);
		object.SetCopyable(false);

		object.SetScale(default_scale);
		object.SetTranslation(this_hotspot.GetTranslation() + vec3(0.0, 2.0, 0.0));
	}

	void AddPlaceholderObject(){
		if(object_path == "" || @placeholder_object !is null){
			return;
		}
		int placeholder_object_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", true);
		@placeholder_object = ReadObjectFromID(placeholder_object_id);

		placeholder_object.SetTranslation(object.GetTranslation());
		placeholder_object.SetRotation(object.GetRotation());
		placeholder_object.SetScale(object.GetScale());

		@placeholder = cast<PlaceholderObject@>(placeholder_object);
		UpdatePlaceholderPreview();
	}

	void ReceiveMessage(string message, string identifier){
		if(identifier == "xml_content"){
			//Remove all spaces to eliminate style differences.
			string xml_content = join(message.split(" "), "");
			string model = GetStringBetween(xml_content, "<Model>", "</Model>");
			if(model != ""){
				placeholder.SetPreview(object_path);
				Log(warning, "model found : " + model);
			}else{
				//Check if the target xml is an ItemObject or a Character.
				string obj_path = GetStringBetween(xml_content, "obj_path=\"", "\"");
				if(obj_path != ""){
					object_path = obj_path;
					level.SendMessage("drika_read_file " + hotspot.GetID() + " " + parent.index + " " + obj_path + " " + "xml_content");
				}else{
					//Check if the target xml is an Actor.
					string actor_model = GetStringBetween(xml_content, "<Character>", "</Character>");
					if(actor_model != ""){
						object_path = actor_model;
						level.SendMessage("drika_read_file " + hotspot.GetID() + " " + parent.index + " " + actor_model + " " + "xml_content");
					}else{
						Log(warning, "Could not find model in " + object_path);
					}
				}
			}
		}
	}

	void RemovePlaceholderObject(){
		QueueDeleteObjectID(placeholder_object.GetID());
		@placeholder_object = null;
		@placeholder = null;
	}

	void UpdatePlaceholderPreview(){
		level.SendMessage("drika_read_file " + hotspot.GetID() + " " + parent.index + " " + object_path + " " + "xml_content");
	}

	void DrawEditing(){
		if(@object is null or @placeholder_object is null){
			return;
		}
		UpdatePlaceholderTransform();
	}

	void UpdatePlaceholderTransform(){
		placeholder_object.SetTranslation(object.GetTranslation());
		placeholder_object.SetRotation(object.GetRotation());
		placeholder_object.SetScale(object.GetScale());
	}

	void Remove(){
		if(Exists()){
			QueueDeleteObjectID(id);
		}
		id = -1;
		@object = null;
	}

	void Retrieve(){
		if(duplicating_hotspot || duplicating_function){
			if(ObjectExists(id)){
				//Use the same transform as the original placeholder.
				Object@ old_placeholder = ReadObjectFromID(id);
				Create();
				object.SetScale(old_placeholder.GetScale());
				object.SetTranslation(old_placeholder.GetTranslation());
				object.SetRotation(old_placeholder.GetRotation());
			}else{
				id = -1;
			}
		}else{
			if(ObjectExists(id)){
				@object = ReadObjectFromID(id);
				object.SetName(name);
				object.SetSelectable(false);
			}else{
				Create();
			}
		}
		AddPlaceholderObject();
	}

	bool Exists(){
		return (id != -1 && ObjectExists(id));
	}

	void SetSelected(bool selected){
		if(Exists()){
			object.SetSelected(selected);
		}
	}

	void SetSelectable(bool selectable){
		if(Exists()){
			if(object.IsSelected() && !selectable){
				object.SetSelected(false);
			}
			object.SetSelectable(selectable);
		}
	}

	vec3 GetTranslation(){
		if(Exists()){
			return object.GetTranslation();
		}else{
			return vec3(1.0);
		}
	}

	quaternion GetRotation(){
		if(Exists()){
			return object.GetRotation();
		}else{
			return quaternion();
		}
	}

	vec4 GetRotationVec4(){
		if(Exists()){
			return object.GetRotationVec4();
		}else{
			return vec4(0.0);
		}
	}

	vec3 GetScale(){
		if(Exists()){
			return object.GetScale();
		}else{
			return vec3(1.0);
		}
	}

	bool IsSelected(){
		if(Exists()){
			return object.IsSelected();
		}else{
			return false;
		}
	}

	void SetTranslation(vec3 translation){
		if(Exists()){
			object.SetTranslation(translation);
		}
	}

	void RelativeTranslate(vec3 offset){
		if(Exists()){
			object.SetTranslation(object.GetTranslation() + offset);
			UpdatePlaceholderTransform();
		}
	}

	void SetRotation(quaternion rotation){
		if(Exists()){
			object.SetRotation(rotation);
		}
	}

	void RelativeRotate(vec3 origin, mat4 before_mat, mat4 after_mat){
		if(Exists()){
			vec3 current_translation = object.GetTranslation();

			mat4 inverse_mat = after_mat * invert(before_mat);
			vec3 rotated_point = origin + (inverse_mat * (current_translation - origin));

			mat4 object_mat = object.GetTransform();
			mat4 object_inverse_mat = object_mat * invert(before_mat);
			mat4 rotation_mat = object_inverse_mat * after_mat;
			object.SetRotation(QuaternionFromMat4(rotation_mat));

			object.SetTranslation(rotated_point);
			UpdatePlaceholderTransform();
		}
	}

	void SetScale(vec3 scale){
		if(Exists()){
			object.SetScale(scale);
		}
	}
}
