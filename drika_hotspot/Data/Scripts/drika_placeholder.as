class DrikaPlaceholder{
	int id = -1;
	Object@ object;
	string name;
	vec3 default_scale = vec3(0.25);
	string path = "Data/Objects/drika_hotspot_cube.xml";

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

	void SetRotation(quaternion rotation){
		if(Exists()){
			object.SetRotation(rotation);
		}
	}

	void SetScale(vec3 scale){
		if(Exists()){
			object.SetScale(scale);
		}
	}
}
