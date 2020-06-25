class DrikaPlaceholder{
	int id = -1;
	Object@ object;
	Object@ placeholder_object;
	string name;
	vec3 default_scale = vec3(0.25);
	string path = "Data/Objects/drika_hotspot_cube.xml";
	string object_path;
	DrikaElement@ parent;
	string placeholder_path;
	vec3 bounding_box = vec3(1.0);

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
		if(object_path == ""){
			return;
		}else if(@placeholder_object !is null){
			placeholder_object.SetEnabled(true);
			return;
		}
		UpdatePlaceholderPreview();
	}

	void HidePlaceholderObject(){
		if(@placeholder_object !is null){
			placeholder_object.SetEnabled(false);
		}
	}

	void UpdatePlaceholderPreview(){
		RemovePlaceholderObject();
		level.SendMessage("drika_read_file " + hotspot.GetID() + " " + parent.index + " " + object_path + " " + "xml_content");
	}

	void ReceiveMessage(string message, string identifier){
		if(identifier == "xml_content"){
			//Remove all spaces to eliminate style differences.
			string xml_content = join(message.split(" "), "");
			string model = GetStringBetween(xml_content, "<Model>", "</Model>");
			string colormap = GetStringBetween(xml_content, "<ColorMap>", "</ColorMap>");
			if(model != ""){
				string data = GetPlaceholderXMLData(model, colormap);

				int unique_index = StorageGetInt32("unique_index");
				placeholder_path = "Data/Objects/placeholder/drika_placeholder_" + unique_index + ".xml";
				StorageSetInt32("unique_index", unique_index + 1);

				level.SendMessage("drika_write_file " + hotspot.GetID() + " " + parent.index + " " + placeholder_path + " " + data);
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

	string GetPlaceholderXMLData(string model, string colormap){
		string data = "";

		data += "<?xml\" version=\\\"1.0\\\" ?>\n";
		data += "<Object>\n";
		data += "\t<Model>" + model + "</Model>\n";
		data += "\t<ColorMap>" + colormap + "</ColorMap>\n";
		data += "\t<NormalMap>Data/Textures/chest_n.png</NormalMap>\n";
		data += "\t<ShaderName>drika_placeholder</ShaderName>\n";
		data += "\t<flags no_collision=true/>\n";
		data += "</Object>\n";

		return data;
	}

	void ReceiveMessage(string message){
		if(message == "drika_write_placeholder_done"){
			if(!FileExists(placeholder_path)){
				Log(warning, "Path does not exist " + placeholder_path);
				return;
			}else{
				Log(warning, "Path does exist! " + placeholder_path);
			}

			int placeholder_object_id = CreateObject(placeholder_path, true);
			@placeholder_object = ReadObjectFromID(placeholder_object_id);
			SetBoundingBox(placeholder_object);
			object.SetScale(bounding_box);

			UpdatePlaceholderTransform();
		}
	}

	void SetBoundingBox(Object@ obj){
		vec3 new_bounding_box = obj.GetBoundingBox();
		bounding_box = (new_bounding_box == vec3(0.0)?vec3(1.0):new_bounding_box);
	}

	void RemovePlaceholderObject(){
		if(@placeholder_object !is null){
			QueueDeleteObjectID(placeholder_object.GetID());
		}
		@placeholder_object = null;
		bounding_box = vec3(1.0);
	}

	void DrawEditing(){
		if(@object is null or @placeholder_object is null){
			return;
		}
		UpdatePlaceholderTransform();
	}

	void UpdatePlaceholderTransform(){
		if(@placeholder_object !is null){
			placeholder_object.SetTranslation(object.GetTranslation());
			placeholder_object.SetRotation(object.GetRotation());
			placeholder_object.SetScale(vec3(object.GetScale().x / bounding_box.x, object.GetScale().y / bounding_box.y, object.GetScale().z / bounding_box.z));
		}
	}

	void Remove(){
		if(Exists()){
			QueueDeleteObjectID(id);
		}
		id = -1;
		@object = null;
		RemovePlaceholderObject();
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
			return vec3(object.GetScale().x / bounding_box.x, object.GetScale().y / bounding_box.y, object.GetScale().z / bounding_box.z);
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
