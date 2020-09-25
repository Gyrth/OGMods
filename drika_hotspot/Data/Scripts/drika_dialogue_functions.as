
array<array<IMText@>> dialogue_cache;
IMContainer@ dialogue_ui_container;
IMDivider @dialogue_holder;
IMDivider @dialogue_line;
int line_counter = 0;
vec2 dialogue_holder_size = vec2(1700, 300);

void DialogueAddSay(string actor_name, string text){

	dialogue_cache = {array<IMText@>()};
	int counter = 0;

	//Find the actor settings for so that the UI can be build.
	if(current_actor_settings.name != actor_name){
		bool settings_found = false;

		for(uint i = 0; i < actor_settings.size(); i++){
			if(actor_settings[i].name == actor_name){
				settings_found = true;
				@current_actor_settings = actor_settings[i];
				break;
			}
		}

		if(!settings_found){
			ActorSettings new_settings();
			new_settings.name = actor_name;
			actor_settings.insertLast(@new_settings);
			@current_actor_settings = new_settings;
		}
	}

	if(!show_dialogue){
		show_dialogue = true;
		BuildDialogueUI();
	}

	//First split every word up in the text.
	array<string> words = text.split(" ");
	for(uint i = 0; i < words.size(); i++){
		if(i != 0 && i != words.size()){
			words.insertAt(i, " ");
			i++;
		}
	}
	//Also make sure the new line character are seperate.
	array<string> split_text;
	for(uint i = 0; i < words.size(); i++){
		array<string> new_line_seperated = words[i].split("\n");
		for(uint j = 0; j < new_line_seperated.size(); j++){

			split_text.insertLast(new_line_seperated[j]);
			if(j != new_line_seperated.size() -1){
				split_text.insertLast("\n");
			}
		}
	}

	IMText@ dialogue_text;

	for(uint i = 0; i < split_text.size(); i++){
		string word = split_text[i];
		/* Log(warning, word); */

		if(word != "\n"){
			@dialogue_text = IMText(split_text[i], dialogue_font);
			dialogue_cache[counter].insertLast(dialogue_text);

			dialogue_line.append(dialogue_text, 1.0);
			/* dialogue_text.showBorder(); */
			dialogue_text.setBorderColor(vec4(1.0, 0.0, 0.0, 1.0));
		}else if(word == "\n"){
			//If a new line is found then add a new divider.
			line_counter += 1;
			//Also add a new empty array to the cache.
			dialogue_cache.insertLast(array<IMText@>());
			counter += 1;
			@dialogue_line = IMDivider("dialogue_line" + counter, DOHorizontal);
			dialogue_holder.append(dialogue_line);
			dialogue_line.setZOrdering(2);

			continue;
		}

		imGUI.update();

		/* dialogue_line_holder.showBorder(); */
		/* dialogue_lines_holder_vert.showBorder(); */
		/* dialogue_lines_holder_horiz.showBorder(); */

		bool add_previous_text_to_new_line = dialogue_holder.getSizeX() > dialogue_holder_size.x;
		if(add_previous_text_to_new_line){
			Log(warning, "Remake dialogue ");

			dialogue_cache[counter].removeLast();
			dialogue_cache.insertLast(array<IMText@>());
			counter += 1;
			dialogue_cache[counter].insertLast(dialogue_text);

			/* dialogue_holder.showBorder(); */
			dialogue_holder.clear();
			dialogue_holder.setSize(dialogue_holder_size);
			/* dialogue_line_holder.setSize(dialogue_holder_size); */

			//Remake the dialogue using the cache.
			for(uint j = 0; j < dialogue_cache.size(); j++){
				@dialogue_line = IMDivider("dialogue_line" + counter, DOHorizontal);
				dialogue_holder.append(dialogue_line);
				dialogue_line.setZOrdering(2);
				for(uint k = 0; k < dialogue_cache[j].size(); k++){
					dialogue_line.append(dialogue_cache[j][k]);
				}
			}
		}
	}
}

void BuildDialogueUI(){
	ui_created = false;
	line_counter = 0;
	DisposeTextAtlases();
	dialogue_container.clear();
	@dialogue_ui_container = IMContainer(2560, 500);
	if(dialogue_location == dialogue_bottom){
		dialogue_container.setAlignment(CACenter, CABottom);
	}else{
		dialogue_container.setAlignment(CACenter, CATop);
	}
	/* dialogue_ui_container.showBorder(); */
	dialogue_ui_container.setAlignment(CACenter, CACenter);
	dialogue_container.setElement(dialogue_ui_container);
	dialogue_container.setSize(vec2(2560, 1440));

	CreateNameTag(dialogue_ui_container);
	CreateBackground(dialogue_ui_container);

	switch(dialogue_layout){
		case default_layout:
			DefaultUI(dialogue_ui_container);
			break;
		case simple_layout:
			SimpleUI(dialogue_ui_container);
			break;
		case breath_of_the_wild_layout:
			BreathOfTheWildUI(dialogue_ui_container);
			break;
		case chrono_trigger_layout:
			ChronoTriggerUI(dialogue_ui_container);
			break;
		case fallout_3_green_layout:
			Fallout3UI(dialogue_ui_container);
			break;
		case luigis_mansion_layout:
			LuigisMansionUI(dialogue_ui_container);
			break;
		default :
			break;
	}

	CreateChoiceUI();

	ui_created = true;
}

void CreateChoiceUI(){
	if(!showing_choice){
		return;
	}

	choice_ui_elements.resize(0);

	for(uint i = 0; i < choices.size(); i++){
		line_counter += 1;
		IMDivider line_divider("dialogue_line_holder" + line_counter, DOHorizontal);
		line_divider.setZOrdering(2);

		IMContainer choice_container(1500, -1);
		IMMessage on_click("drika_dialogue_choice_pick", i);
		IMMessage on_hover_enter("drika_dialogue_choice_select", i);
	    IMMessage nil_message("");
		choice_container.addLeftMouseClickBehavior(IMFixedMessageOnClick(on_click), "");
		choice_container.addMouseOverBehavior(IMFixedMessageOnMouseOver(on_hover_enter, nil_message, nil_message), "");
		dialogue_holder.append(choice_container);
		choice_container.setZOrdering(2);
		choice_container.setBorderColor(dialogue_font.color);
		choice_container.setBorderSize(2.0f);

		IMText choice_text(choices[i], dialogue_font);
		choice_text.addUpdateBehavior(IMFadeIn(250, inSineTween ), "");
		choice_container.setElement(line_divider);

		line_divider.appendSpacer(20.0f);
		line_divider.append(choice_text);
		line_divider.appendSpacer(20.0f);
		choice_ui_elements.insertLast(@choice_container);
	}

	SelectChoice(selected_choice);
}

void DefaultUI(IMContainer@ parent){
	parent.setSizeY(500.0);
	dialogue_holder_size = vec2(1700, 400);
	vec2 dialogue_holder_offset = vec2(100.0, 125.0);

	@dialogue_holder = IMDivider("dialogue_holder", DOVertical);
	dialogue_holder.setAlignment(CALeft, CATop);
	/* dialogue_holder.showBorder(); */
	parent.addFloatingElement(dialogue_holder, "dialogue_holder", dialogue_holder_offset, -1);

	@dialogue_line = IMDivider("dialogue_line" + line_counter, DOHorizontal);
	dialogue_holder.append(dialogue_line);
	dialogue_line.setZOrdering(2);

	bool use_keyboard = (max(last_mouse_event_time, last_keyboard_event_time) > last_controller_event_time);

	IMContainer controls_container(2300.0, 300.0);
	controls_container.setAlignment(CABottom, CARight);
	IMDivider controls_divider("controls_divider", DOVertical);
	controls_divider.setAlignment(CATop, CALeft);
	controls_divider.setZOrdering(1);
	controls_container.setElement(controls_divider);
	@lmb_continue = IMText(GetStringDescriptionForBinding(use_keyboard?"key":"gamepad_0", "attack") + " to continue", controls_font);
	@rtn_skip = IMText(GetStringDescriptionForBinding(use_keyboard?"key":"gamepad_0", "skip_dialogue")+" to skip", controls_font);
	controls_divider.append(lmb_continue);
	controls_divider.append(rtn_skip);

	lmb_continue.setVisible(false);
	rtn_skip.setVisible(false);
	/* parent.addFloatingElement(controls_container, "controls_container", vec2(0.0, 0.0), -1); */
}

void SimpleUI(IMContainer@ parent){
	parent.setAlignment(CACenter, CACenter);
	/* parent.showBorder(); */

	/* @dialogue_lines_holder_horiz = IMDivider("dialogue_lines_holder_horiz", DOHorizontal);
	dialogue_lines_holder_horiz.setAlignment(CACenter, CATop);
	@dialogue_lines_holder_vert = IMDivider("dialogue_lines_holder_vert", DOVertical);
	dialogue_lines_holder_horiz.append(dialogue_lines_holder_vert);
	dialogue_lines_holder_vert.setAlignment(CACenter, CATop);

	@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
	dialogue_lines_holder_vert.append(dialogue_line_holder);
	dialogue_line_holder.setZOrdering(2); */

	//Add all the text that has already been added, in case of a refresh.
	/* for(uint i = 0; i < dialogue_cache.size(); i++){
		IMText dialogue_text(dialogue_cache[i], dialogue_font);
		dialogue_line_holder.append(dialogue_text);

		line_counter += 1;
		@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
		dialogue_lines_holder_vert.append(dialogue_line_holder);
		dialogue_line_holder.setZOrdering(2);
	} */

	/* parent.setElement(dialogue_lines_holder_horiz); */
}

void BreathOfTheWildUI(IMContainer@ parent){
	/* parent.setAlignment(CACenter, CACenter); */
	/* parent.showBorder(); */
	parent.setSizeY(400.0);

	vec2 size = vec2(1600, 300);

	/* @dialogue_holder = IMContainer(size.x, size.y);
	dialogue_holder.setAlignment(CACenter, CATop); */

	/* @dialogue_lines_holder_horiz = IMDivider("dialogue_lines_holder_horiz", DOHorizontal);
	dialogue_holder.setElement(dialogue_lines_holder_horiz); */
	/* dialogue_holder.addFloatingElement(dialogue_lines_holder_horiz, "dialogue_lines_holder_horiz", vec2(0.0, 0.0), -1); */

	/* @dialogue_lines_holder_vert = IMDivider("dialogue_lines_holder_vert", DOVertical);
	dialogue_lines_holder_horiz.append(dialogue_lines_holder_vert); */

	/* dialogue_lines_holder_horiz.setAlignment(CACenter, CATop); */
	/* dialogue_lines_holder_vert.setAlignment(CACenter, CATop); */

	/* dialogue_lines_holder_horiz.showBorder(); */
	/* dialogue_lines_holder_vert.showBorder(); */

	/* @dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
	dialogue_lines_holder_vert.append(dialogue_line_holder);
	dialogue_line_holder.setZOrdering(2); */

	//Add all the text that has already been added, in case of a refresh.
	/* for(uint i = 0; i < dialogue_cache.size(); i++){
		IMText dialogue_text(dialogue_cache[i], dialogue_font);
		dialogue_line_holder.append(dialogue_text);

		line_counter += 1;
		@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
		dialogue_lines_holder_vert.append(dialogue_line_holder);
		dialogue_line_holder.setZOrdering(2);
	} */

	/* parent.addFloatingElement(dialogue_holder, "dialogue_holder", vec2(475.0, 65.0), -1); */
	/* parent.showBorder(); */
}

void ChronoTriggerUI(IMContainer@ parent){
	parent.setAlignment(CACenter, CABottom);
	/* parent.showBorder(); */
	parent.setSizeY(450.0);

	/* @dialogue_holder = IMContainer(1500, 300);
	dialogue_holder.setAlignment(CALeft, CATop); */
	/* dialogue_holder.showBorder(); */

	/* @dialogue_lines_holder_horiz = IMDivider("dialogue_lines_holder_horiz", DOHorizontal);
	dialogue_holder.setElement(dialogue_lines_holder_horiz);
	dialogue_lines_holder_horiz.setAlignment(CACenter, CATop);
	@dialogue_lines_holder_vert = IMDivider("dialogue_lines_holder_vert", DOVertical);
	dialogue_lines_holder_horiz.append(dialogue_lines_holder_vert);
	dialogue_lines_holder_vert.setAlignment(CALeft, CATop);

	@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
	dialogue_lines_holder_vert.append(dialogue_line_holder);
	dialogue_line_holder.setZOrdering(2); */

	//Add all the text that has already been added, in case of a refresh.
	/* for(uint i = 0; i < dialogue_cache.size(); i++){
		IMText dialogue_text(dialogue_cache[i], dialogue_font);
		dialogue_line_holder.append(dialogue_text);

		line_counter += 1;
		@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
		dialogue_lines_holder_vert.append(dialogue_line_holder);
		dialogue_line_holder.setZOrdering(2);
	} */

	/* parent.setElement(dialogue_holder); */
}

void Fallout3UI(IMContainer@ parent){
	parent.setAlignment(CACenter, CABottom);
	/* parent.showBorder(); */
	parent.setSizeY(450.0);

	/* @dialogue_holder = IMContainer(1400, 400);
	dialogue_holder.setAlignment(CALeft, CATop); */
	/* dialogue_holder.showBorder(); */

	/* @dialogue_lines_holder_horiz = IMDivider("dialogue_lines_holder_horiz", DOHorizontal);
	dialogue_holder.setElement(dialogue_lines_holder_horiz);
	dialogue_lines_holder_horiz.setAlignment(CACenter, CATop);
	@dialogue_lines_holder_vert = IMDivider("dialogue_lines_holder_vert", DOVertical);
	dialogue_lines_holder_horiz.append(dialogue_lines_holder_vert);
	dialogue_lines_holder_vert.setAlignment(CALeft, CATop);

	@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
	dialogue_lines_holder_vert.append(dialogue_line_holder);
	dialogue_line_holder.setZOrdering(2); */

	//Add all the text that has already been added, in case of a refresh.
	/* for(uint i = 0; i < dialogue_cache.size(); i++){
		IMText dialogue_text(dialogue_cache[i], dialogue_font);
		dialogue_line_holder.append(dialogue_text);

		line_counter += 1;
		@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
		dialogue_lines_holder_vert.append(dialogue_line_holder);
		dialogue_line_holder.setZOrdering(2);
	} */

	/* parent.setElement(dialogue_holder); */
}

void LuigisMansionUI(IMContainer@ parent){
	parent.setAlignment(CACenter, CABottom);
	/* parent.showBorder(); */
	parent.setSizeY(450.0);

	vec2 size = vec2(1850, 350);

	/* @dialogue_holder = IMContainer(size.x, size.y);
	dialogue_holder.setAlignment(CARight, CACenter); */

	/* @dialogue_lines_holder_horiz = IMDivider("dialogue_lines_holder_horiz", DOHorizontal);
	dialogue_holder.addFloatingElement(dialogue_lines_holder_horiz, "dialogue_lines_holder_horiz", vec2(0.0, 0.0), -1);
	dialogue_lines_holder_horiz.setAlignment(CALeft, CATop);
	@dialogue_lines_holder_vert = IMDivider("dialogue_lines_holder_vert", DOVertical);
	dialogue_lines_holder_horiz.append(dialogue_lines_holder_vert);
	dialogue_lines_holder_vert.setAlignment(CALeft, CATop);

	@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
	dialogue_lines_holder_vert.append(dialogue_line_holder);
	dialogue_line_holder.setZOrdering(2); */

	//Add all the text that has already been added, in case of a refresh.
	/* for(uint i = 0; i < dialogue_cache.size(); i++){
		IMText dialogue_text(dialogue_cache[i], dialogue_font);
		dialogue_line_holder.append(dialogue_text);

		line_counter += 1;
		@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
		dialogue_lines_holder_vert.append(dialogue_line_holder);
		dialogue_line_holder.setZOrdering(2);
	} */

	/* parent.addFloatingElement(dialogue_holder, "dialogue_holder", vec2(450.0, 0.0), -1); */
}

void CreateBackground(IMContainer@ parent){
	if(!show_dialogue){
		return;
	}

	switch(dialogue_layout){
		case default_layout:
			DefaultBackground(parent);
			break;
		case simple_layout:
			SimpleBackground(parent);
			break;
		case breath_of_the_wild_layout:
			BreathOfTheWildBackground(parent);
			break;
		case chrono_trigger_layout:
			ChronoTriggerBackground(parent);
			break;
		case fallout_3_green_layout:
			Fallout3Background(parent);
			break;
		case luigis_mansion_layout:
			LuigisMansionBackground(parent);
			break;
		default :
			break;
	}
}

void DefaultBackground(IMContainer@ parent){
	//Remove any background that's already there.
	parent.removeElement("bg_container");

	IMContainer bg_container(0.0, 0.0);
	IMDivider bg_divider("bg_divider", DOHorizontal);
	bg_divider.setZOrdering(-1);
	bg_container.setElement(bg_divider);
	/* bg_container.showBorder(); */

	float bg_alpha = 0.5;
	float bg_height = 350.0;
	vec2 background_offset = vec2(0.0, 75.0);

	vec4 color = showing_choice?dialogue_font.color:current_actor_settings.color;

	IMImage left_fade("Textures/ui/dialogue/dialogue_bg-fade.png");
	left_fade.setColor(color);
	left_fade.setSizeX(500.0);
	left_fade.setSizeY(bg_height);
	left_fade.setAlpha(bg_alpha);
	left_fade.setClip(false);
	left_fade.setDisplacementX(0.25);
	bg_divider.append(left_fade);

	IMImage middle_fade("Textures/ui/dialogue/dialogue_bg.png");
	middle_fade.setColor(color);
	middle_fade.setSizeX(1560.0);
	middle_fade.setSizeY(bg_height);
	middle_fade.setAlpha(bg_alpha);
	middle_fade.setClip(false);
	bg_divider.append(middle_fade);

	IMImage right_fade("Textures/ui/dialogue/dialogue_bg-fade_reverse.png");
	right_fade.setColor(color);
	right_fade.setSizeX(500.0);
	right_fade.setSizeY(bg_height);
	right_fade.setAlpha(bg_alpha);
	right_fade.setClip(false);
	right_fade.setDisplacementX(-0.25);
	bg_divider.append(right_fade);

	parent.addFloatingElement(bg_container, "bg_container", background_offset, -1);
	/* parent.showBorder(); */
}

void SimpleBackground(IMContainer@ parent){
	//Remove any background that's already there.
	parent.removeElement("bg_container");

	IMContainer bg_container(0.0, 0.0);
	IMDivider bg_divider("bg_divider", DOHorizontal);
	bg_divider.setZOrdering(-1);
	bg_container.setElement(bg_divider);

	float bg_alpha = 1.0;
	float bg_height = 450.0;

	IMImage middle_fade("Textures/dialogue_bg_nametag_faded.png");
	middle_fade.setSizeX(2560);
	middle_fade.setSizeY(bg_height);
	middle_fade.setAlpha(bg_alpha);
	middle_fade.setClip(false);
	bg_divider.append(middle_fade);

	parent.addFloatingElement(bg_container, "bg_container", vec2(0.0), -1);
}

void BreathOfTheWildBackground(IMContainer@ parent){
	//Remove any background that's already there.
	parent.removeElement("bg_container");

	IMContainer bg_container(0.0, 0.0);
	IMDivider bg_divider("bg_divider", DOHorizontal);
	bg_divider.setZOrdering(-1);
	bg_container.setElement(bg_divider);

	float bg_alpha = 0.5;
	float bg_height = 400.0;

	IMImage left_fade("Textures/dialogue_bg_botw_left.png");
	left_fade.setSizeX(bg_height);
	left_fade.setSizeY(bg_height);
	left_fade.setAlpha(bg_alpha);
	left_fade.setClip(false);
	left_fade.setDisplacementX(0.25);
	bg_divider.append(left_fade);

	IMImage middle_fade("Textures/dialogue_bg_botw_middle.png");
	middle_fade.setSizeX(1000.0);
	middle_fade.setSizeY(bg_height);
	middle_fade.setAlpha(bg_alpha);
	middle_fade.setClip(false);
	bg_divider.append(middle_fade);

	IMImage right_fade("Textures/dialogue_bg_botw_right.png");
	right_fade.setSizeX(bg_height);
	right_fade.setSizeY(bg_height);
	right_fade.setAlpha(bg_alpha);
	right_fade.setClip(false);
	right_fade.setDisplacementX(-0.25);
	bg_divider.append(right_fade);

	float whole_width = (bg_height * 2.0 + 1000.0);
	parent.addFloatingElement(bg_container, "bg_container", vec2((2560 / 2.0) - (whole_width / 2.0), 0.0), -1);
}

void ChronoTriggerBackground(IMContainer@ parent){
	//Remove any background that's already there.
	parent.removeElement("bg_container");

	IMContainer bg_container(0.0, 0.0);
	IMDivider bg_divider("bg_divider", DOHorizontal);
	bg_divider.setZOrdering(-1);
	bg_container.setElement(bg_divider);

	float bg_alpha = 1.0;
	float bg_height = 450.0;
	float side_width = 50.0;

	IMImage left_fade("Textures/dialogue_bg_ct_left.png");
	left_fade.setSizeX(side_width);
	left_fade.setSizeY(bg_height);
	left_fade.setAlpha(bg_alpha);
	left_fade.setClip(false);
	left_fade.setDisplacementX(0.25);
	bg_divider.append(left_fade);

	IMImage middle_fade("Textures/dialogue_bg_ct_middle.png");
	middle_fade.setSizeX(1500.0);
	middle_fade.setSizeY(bg_height);
	middle_fade.setAlpha(bg_alpha);
	middle_fade.setClip(false);
	bg_divider.append(middle_fade);

	IMImage right_fade("Textures/dialogue_bg_ct_right.png");
	right_fade.setSizeX(side_width);
	right_fade.setSizeY(bg_height);
	right_fade.setAlpha(bg_alpha);
	right_fade.setClip(false);
	right_fade.setDisplacementX(-0.25);
	bg_divider.append(right_fade);

	float whole_width = (side_width * 2.0 + 1500.0);
	parent.addFloatingElement(bg_container, "bg_container", vec2((2560 / 2.0) - (whole_width / 2.0), 0.0), -1);
}

void Fallout3Background(IMContainer@ parent){
	//Remove any background that's already there.
	parent.removeElement("bg_container");

	IMContainer bg_container(0.0, 0.0);
	IMDivider bg_divider("bg_divider", DOHorizontal);
	bg_divider.setZOrdering(-1);
	bg_container.setElement(bg_divider);

	float bg_alpha = 0.5;
	float bg_height = 400.0;
	float side_width = 5.0;
	vec4 color = showing_choice?dialogue_font.color:current_actor_settings.color;

	IMImage left_fade("Textures/dialogue_bg_fo3_end.png");
	left_fade.setColor(color);
	left_fade.setSizeX(side_width);
	left_fade.setSizeY(bg_height);
	left_fade.setAlpha(bg_alpha);
	left_fade.setClip(false);
	left_fade.setDisplacementX(0.25);
	bg_divider.append(left_fade);

	IMImage middle_fade("Textures/ui/dialogue/dialogue_bg.png");
	middle_fade.setColor(color);
	middle_fade.setSizeX(1500.0);
	middle_fade.setSizeY(bg_height);
	middle_fade.setAlpha(bg_alpha);
	middle_fade.setClip(false);
	bg_divider.append(middle_fade);

	IMImage right_fade("Textures/dialogue_bg_fo3_end.png");
	right_fade.setColor(color);
	right_fade.setSizeX(side_width);
	right_fade.setSizeY(bg_height);
	right_fade.setAlpha(bg_alpha);
	right_fade.setClip(false);
	right_fade.setDisplacementX(-0.25);
	bg_divider.append(right_fade);

	float whole_width = (side_width * 2.0 + 1500.0);
	parent.addFloatingElement(bg_container, "bg_container", vec2((2560 / 2.0) - (whole_width / 2.0), 0.0), -1);
}

void LuigisMansionBackground(IMContainer@ parent){
	//Remove any background that's already there.
	parent.removeElement("bg_container");

	IMContainer bg_container(0.0, 0.0);
	IMDivider bg_divider("bg_divider", DOHorizontal);
	bg_divider.setZOrdering(-1);
	bg_container.setElement(bg_divider);

	float bg_alpha = 0.75;
	float bg_height = 350.0;
	float side_width = bg_height / 2.0;
	float middle_width = 1800.0;
	vec4 color = showing_choice?dialogue_font.color:current_actor_settings.color;

	IMImage left_fade("Textures/dialogue_bg_lm_left.png");
	left_fade.setColor(color);
	left_fade.setAlpha(bg_alpha);
	left_fade.scaleToSizeY(bg_height);
	left_fade.setClip(false);
	left_fade.setDisplacementX(0.25);
	bg_divider.append(left_fade);

	IMImage middle_fade("Textures/dialogue_bg_lm_middle.png");
	middle_fade.setColor(color);
	middle_fade.setAlpha(bg_alpha);
	middle_fade.setSizeX(middle_width);
	middle_fade.setSizeY(bg_height);
	middle_fade.setClip(false);
	bg_divider.append(middle_fade);

	IMImage right_fade("Textures/dialogue_bg_lm_right.png");
	right_fade.setColor(color);
	right_fade.setAlpha(bg_alpha);
	right_fade.scaleToSizeY(bg_height);
	right_fade.setClip(false);
	right_fade.setDisplacementX(-0.25);
	bg_divider.append(right_fade);

	float whole_width = (side_width * 2.0 + middle_width);
	parent.addFloatingElement(bg_container, "bg_container", vec2((2560 / 2.0) - (whole_width / 2.0), 0.0), -1);
	/* bg_container.showBorder(); */
	dialogue_move_in_timer = dialogue_move_in_duration;
	dialogue_move_in = true;
}

void CreateNameTag(IMContainer@ parent){
	if(!show_dialogue || showing_choice){
		return;
	}

	switch(dialogue_layout){
		case default_layout:
			DefaultNameTag(parent);
			break;
		case simple_layout:
			SimpleNameTag(parent);
			break;
		case breath_of_the_wild_layout:
			BreathOfTheWildNameTag(parent);
			break;
		case chrono_trigger_layout:
			ChronoTriggerNameTag(parent);
			break;
		case fallout_3_green_layout:
			Fallout3NameTag(parent);
			break;
		case luigis_mansion_layout:
			LuigisMansionNameTag(parent);
			break;
		default :
			break;
	}
}

void DefaultNameTag(IMContainer@ parent){
	//Remove any nametag that's already there.
	parent.removeElement("name_container");

	IMContainer name_container(0.0, 125.0);
	IMDivider name_divider("name_divider", DOHorizontal);
	name_divider.setZOrdering(2);
	name_divider.setAlignment(CACenter, CACenter);
	name_container.setElement(name_divider);

	vec2 offset(0.0, 15.0);

	if(show_names){
		IMText name(current_actor_settings.name, name_font);
		name_divider.appendSpacer(50.0);
		name_divider.append(name);
		name_divider.appendSpacer(50.0);
		name.setColor(current_actor_settings.color);

		IMImage name_background("Textures/ui/menus/main/brushStroke.png");
		name_background.setClip(false);
		parent.addFloatingElement(name_container, "name_container", offset, 3);

		imGUI.update();
		name_background.setSize(name_container.getSize());
		name_container.addFloatingElement(name_background, "name_background", vec2(0, 0), 1);
		name_background.setZOrdering(1);
	}
}

void SimpleNameTag(IMContainer@ parent){
	//Remove any nametag that's already there.
	parent.removeElement("nametag_container");

	IMContainer nametag_container(0.0, 0.0);
	IMDivider nametag_divider("nametag_divider", DOHorizontal);
	nametag_container.setElement(nametag_divider);
	nametag_divider.setAlignment(CACenter, CATop);

	if(current_actor_settings.avatar_path != "None" && show_avatar){
		IMImage avatar_image(current_actor_settings.avatar_path);
		avatar_image.setSize(vec2(400, 400));
		nametag_divider.append(avatar_image);
	}

	IMContainer name_container(-1.0, dialogue_font.size);
	name_container.setAlignment(CACenter, CACenter);
	IMDivider name_divider("name_divider", DOHorizontal);
	name_divider.setZOrdering(3);
	name_divider.setAlignment(CACenter, CACenter);
	name_container.setElement(name_divider);
	nametag_divider.append(name_container);

	if(show_names){
		IMText name(current_actor_settings.name, name_font_arial);
		name_divider.appendSpacer(60.0);
		name_divider.append(name);
		name_divider.appendSpacer(60.0);
		name.setColor(current_actor_settings.color);

		IMImage name_background("Textures/dialogue_bg_nametag_faded.png");
		name_background.setClip(false);
		name_background.setAlpha(0.75);

		imGUI.update();
		name_background.setSize(name_container.getSize());
		name_container.addFloatingElement(name_background, "name_background", vec2(0, 0), 1);
		name_background.setZOrdering(1);
	}
	parent.addFloatingElement(nametag_container, "nametag_container", vec2(300, -50), 3);
}

void BreathOfTheWildNameTag(IMContainer@ parent){
	//Remove any nametag that's already there.
	parent.removeElement("name_container");

	IMContainer name_container(0.0, 100.0);
	IMDivider name_divider("name_divider", DOHorizontal);
	name_divider.setZOrdering(3);
	name_divider.setAlignment(CACenter, CACenter);
	name_container.setElement(name_divider);

	if(current_actor_settings.avatar_path != "None" && show_avatar){
		IMImage avatar_image(current_actor_settings.avatar_path);
		avatar_image.setSize(vec2(350, 350));
		avatar_image.setClip(false);
		name_container.addFloatingElement(avatar_image, "avatar", vec2(-500, 50), 3);
	}

	if(show_names){
		IMText name(current_actor_settings.name, dialogue_font);
		name_divider.appendSpacer(30.0);
		name_divider.append(name);
		name_divider.appendSpacer(30.0);
		name.setColor(current_actor_settings.color);
	}

	parent.addFloatingElement(name_container, "name_container", vec2(550, -(dialogue_font.size / 4.0)), 3);
}

void ChronoTriggerNameTag(IMContainer@ parent){
	//Remove any nametag that's already there.
	parent.removeElement("name_container");

	IMContainer name_container(0.0, 100.0);
	IMDivider name_divider("name_divider", DOHorizontal);
	name_divider.setZOrdering(3);
	name_divider.setAlignment(CACenter, CACenter);
	name_container.setElement(name_divider);

	if(current_actor_settings.avatar_path != "None" && show_avatar){
		IMImage avatar_image(current_actor_settings.avatar_path);
		avatar_image.setSize(vec2(350, 350));
		avatar_image.setClip(false);
		name_container.addFloatingElement(avatar_image, "avatar", vec2(-450, 25), 3);
	}

	if(show_names){
		IMText name(current_actor_settings.name + " : ", dialogue_font);
		name_divider.appendSpacer(30.0);
		name_divider.append(name);
		name_divider.appendSpacer(30.0);
		name.setColor(current_actor_settings.color);
	}

	parent.addFloatingElement(name_container, "name_container", vec2(500.0, dialogue_font.size / 2.0), 3);
}

void Fallout3NameTag(IMContainer@ parent){
	//Remove any nametag that's already there.
	parent.removeElement("name_container");

	IMContainer name_container(parent.getSizeX(), dialogue_font.size);
	name_container.setAlignment(CACenter, CACenter);
	IMDivider name_divider("name_divider", DOHorizontal);
	name_divider.setZOrdering(3);
	name_divider.setAlignment(CACenter, CACenter);
	name_container.setElement(name_divider);

	if(current_actor_settings.avatar_path != "None" && show_avatar){
		IMImage avatar_image(current_actor_settings.avatar_path);
		avatar_image.setSize(vec2(350, 350));
		avatar_image.setClip(false);
		name_container.addFloatingElement(avatar_image, "avatar", vec2(-1050, 100), 3);
	}

	if(show_names){
		IMText name(current_actor_settings.name, dialogue_font);
		name_divider.append(name);
		name.setColor(current_actor_settings.color);
	}

	parent.addFloatingElement(name_container, "name_container", vec2(0.0, -dialogue_font.size), 3);

}

void LuigisMansionNameTag(IMContainer@ parent){
	//Remove any nametag that's already there.
	parent.removeElement("name_container");

	IMContainer name_container(parent.getSizeX(), dialogue_font.size);
	name_container.setAlignment(CACenter, CACenter);
	IMDivider name_divider("name_divider", DOHorizontal);
	name_divider.setZOrdering(3);
	name_divider.setAlignment(CACenter, CACenter);
	name_container.setElement(name_divider);

	if(current_actor_settings.avatar_path != "None" && show_avatar){
		IMImage avatar_image(current_actor_settings.avatar_path);
		avatar_image.setSize(vec2(250, 250));
		avatar_image.setClip(false);
		name_container.addFloatingElement(avatar_image, "avatar", vec2(200.0, 150.0), 3);
	}

	if(show_names){
		IMText name(current_actor_settings.name, dialogue_font);
		name_divider.append(name);
		name.setColor(current_actor_settings.color);
	}

	parent.addFloatingElement(name_container, "name_container", vec2(0.0, -dialogue_font.size), 3);
}
