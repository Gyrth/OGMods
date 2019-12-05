class DrikaComment : DrikaElement{
	string comment;

	DrikaComment(JSONValue params = JSONValue()){
		comment = GetJSONString(params, "comment", "drika_comment");
		drika_element_type = drika_comment;
		has_settings = true;
	}

	JSONValue GetSaveData(){
		JSONValue data;
		data["function_name"] = JSONValue("comment");
		data["comment"] = JSONValue(comment);
		return data;
	}

	string GetDisplayString(){
		return "Comment: " + comment + " ";
	}

	void DrawSettings(){
		ImGui_InputText(" ", comment, 64);
	}

	bool Trigger(){
		return true;
	}
}
