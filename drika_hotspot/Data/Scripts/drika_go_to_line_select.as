class GoToLineSelect{
	string name;
	int index;
	DrikaElement@ target_element;

	GoToLineSelect(string _name, JSONValue params = JSONValue()){
		name = _name;
		index = GetJSONInt(params, name, 0);
		if(duplicating_function){
			@target_element = drika_elements[drika_indexes[index]];
		}
	}

	void PostInit(){
		if(duplicating_hotspot || !duplicating_function){
			@target_element = drika_elements[drika_indexes[index]];
		}
	}

	void SaveGoToLine(JSONValue &inout data){
		if(@target_element != null){
			data[name] = JSONValue(target_element.index);
		}
	}

	void CheckLineAvailable(){
		//Elements can be deleted when this function isn't being edited. So this function is used to continuesly check the target element.
		if(@target_element == null || target_element.deleted){
			//If the line_element gets deleted then just pick the first one.
			if(drika_elements.size() > 0){
				//Check if the first element wasn't the one that got deleted.
				if(!drika_elements[0].deleted){
					@target_element = drika_elements[0];
					return;
				}
			}
			@target_element = null;
		}
	}

	int GetTargetLineIndex(){
		if(@target_element != null){
			return target_element.index;
		}
		return 0;
	}

	void DrawGoToLineUI(){
		if(@target_element == null){
			return;
		}

		string preview_value = target_element.line_number + target_element.GetDisplayString();
		ImGui_AlignTextToFramePadding();
		ImGui_Text("Go to line");
		ImGui_SameLine();
		ImGui_PushStyleColor(ImGuiCol_Text, target_element.GetDisplayColor());
		if(ImGui_BeginCombo("###line" + name, preview_value, ImGuiComboFlags_HeightLarge)){
			for(uint i = 0; i < drika_indexes.size(); i++){
				int item_no = drika_indexes[i];
				bool is_selected = (target_element.index == drika_elements[drika_indexes[i]].index);
				vec4 text_color = drika_elements[item_no].GetDisplayColor();

				ImGui_PushStyleColor(ImGuiCol_Text, text_color);
				if(ImGui_Selectable(drika_elements[item_no].line_number + drika_elements[item_no].GetDisplayString(), is_selected)){
					@target_element = drika_elements[item_no];
				}
				ImGui_PopStyleColor();
			}
			ImGui_EndCombo();
		}
		ImGui_PopStyleColor();
	}
}
