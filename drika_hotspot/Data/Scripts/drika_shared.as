enum dialogue_layouts	{
							default_layout = 0,
							simple_layout = 1,
							breath_of_the_wild_layout = 2,
							chrono_trigger_layout = 3,
							fallout_3_layout = 4,
							luigis_mansion_layout = 5,
							mafia_layout = 6
						}

array<string> dialogue_layout_names =	{
											"Default",
											"Simple",
											"Breath Of The Wild",
											"Chrono Trigger",
											"Fallout 3",
											"Luigi's Mansion",
											"Mafia"
										};

enum ui_functions	{
						ui_clear = 0,
						ui_image = 1,
						ui_text = 2,
						ui_font = 3
					}

enum ease_functions	{
						linear = 0,
						easeInSine = 1,
						easeOutSine = 2,
						easeInOutSine = 3,
						easeInQuad = 4,
						easeOutQuad = 5,
						easeInOutQuad = 6,
						easeInCubic = 7,
						easeOutCubic = 8,
						easeInOutCubic = 9,
						easeInQuart = 10,
						easeOutQuart = 11,
						easeInOutQuart = 12,
						easeInQuint = 13,
						easeOutQuint = 14,
						easeInOutQuint = 15,
						easeInExpo = 16,
						easeOutExpo = 17,
						easeInOutExpo = 18,
						easeInCirc = 19,
						easeOutCirc = 20,
						easeInOutCirc = 21,
						easeInBack = 22,
						easeOutBack = 23,
						easeInOutBack = 24,
						easeInElastic = 25,
						easeOutElastic = 26,
						easeInOutElastic = 27,
						easeInBounce = 28,
						easeOutBounce = 29,
						easeInOutBounce = 30
					};

array<string> ease_function_names =	{
										"Linear",
										"EaseInSine",
										"EaseOutSine",
										"EaseInOutSine",
										"EaseInQuad",
										"EaseOutQuad",
										"EaseInOutQuad",
										"EaseInCubic",
										"EaseOutCubic",
										"EaseInOutCubic",
										"EaseInQuart",
										"EaseOutQuart",
										"EaseInOutQuart",
										"EaseInQuint",
										"EaseOutQuint",
										"EaseInOutQuint",
										"EaseInExpo",
										"EaseOutExpo",
										"EaseInOutExpo",
										"EaseInCirc",
										"EaseOutCirc",
										"EaseInOutCirc",
										"EaseInBack",
										"EaseOutBack",
										"EaseInOutBack",
										"EaseInElastic",
										"EaseOutElastic",
										"EaseInOutElastic",
										"EaseInBounce",
										"EaseOutBounce",
										"EaseInOutBounce"
									};

enum dialogue_locations {
							dialogue_bottom = 0,
							dialogue_top = 1
						}

array<string> dialogue_location_names =	{
											"Bottom",
											"Top"
										};

enum script_entry_types {
							empty_entry,
							character_entry,
							new_line_entry,
							wait_entry,
							start_red_text_entry,
							start_green_text_entry,
							start_blue_text_entry,
							end_coloured_text_entry
						}

enum special_fonts	{
						none,
						red,
						green,
						blue
					}

class DialogueScriptEntry{
	script_entry_types script_entry_type;
	float wait;
	string character;
	IMText @text;
	int line;

	DialogueScriptEntry(script_entry_types script_entry_type){
		this.script_entry_type = script_entry_type;
	}
}

array<DialogueScriptEntry@> InterpDialogueScript(string script_text){
	array<DialogueScriptEntry@> new_dialogue_script;
	array<string> script_text_split;

	//Get all the character seperate.
	for(uint i = 0; i < script_text.length(); i++){
		script_text_split.insertLast(script_text.substr(i, 1));
	}

	for(uint i = 0; i < script_text_split.size(); i++){
		//When the next character is an opening bracket then it might be a command.
		if(script_text_split[i] == "["){
			//Get the locaton of the end bracket so that we can get the whole command inside.
			int end_bracket_index = script_text.findFirst("]", i);
			if(end_bracket_index != -1){
				string command = script_text.substr(i + 1, end_bracket_index - (i + 1));
				//Check if the first 4 letters turn out to be a wait command.
				if(command.substr(0, 4) == "wait"){
					float wait_amount = atof(command.substr(4, command.length() - 4));
					DialogueScriptEntry entry(wait_entry);
					entry.wait = wait_amount;
					new_dialogue_script.insertLast(entry);
					// Skip adding the whole content of inside the brackets.
					i = end_bracket_index;
					continue;
				}else if(command.substr(0, 3) == "red"){
					DialogueScriptEntry entry(start_red_text_entry);
					new_dialogue_script.insertLast(entry);
					i = end_bracket_index;
					continue;
				}else if(command.substr(0, 5) == "green"){
					DialogueScriptEntry entry(start_green_text_entry);
					new_dialogue_script.insertLast(entry);
					i = end_bracket_index;
					continue;
				}else if(command.substr(0, 4) == "blue"){
					DialogueScriptEntry entry(start_blue_text_entry);
					new_dialogue_script.insertLast(entry);
					i = end_bracket_index;
					continue;
				}else if(command.substr(0, 1) == "/"){
					DialogueScriptEntry entry(end_coloured_text_entry);
					new_dialogue_script.insertLast(entry);
					i = end_bracket_index;
					continue;
				}
			}
		}else if(script_text_split[i] == "\n"){
			DialogueScriptEntry entry(new_line_entry);
			new_dialogue_script.insertLast(entry);
			continue;
		}
		DialogueScriptEntry entry(character_entry);
		entry.character = script_text_split[i];
		new_dialogue_script.insertLast(entry);
	}

	return new_dialogue_script;
}

float EaseInSine(float progress){
	return 1 - cos((progress * PI) / 2);
}

float EaseOutSine(float progress){
	return sin((progress * PI) / 2);
}

float EaseInOutSine(float progress){
	return -(cos(PI * progress) - 1) / 2;
}

float EaseInQuad(float progress){
	return progress * progress;
}

float EaseOutQuad(float progress){
	return 1 - (1 - progress) * (1 - progress);
}

float EaseInOutQuad(float progress){
	return progress < 0.5 ? 2 * progress * progress : 1 - pow(-2 * progress + 2, 2) / 2;
}

float EaseInCubic(float progress){
	return progress * progress * progress;
}

float EaseOutCubic(float progress){
	return 1 - pow(1 - progress, 3);
}

float EaseInOutCubic(float progress){
	return progress < 0.5 ? 4 * progress * progress * progress : 1 - pow(-2 * progress + 2, 3) / 2;
}

float EaseInQuart(float progress){
	return progress * progress * progress * progress;
}

float EaseOutQuart(float progress){
	return 1 - pow(1 - progress, 4);
}

float EaseInOutQuart(float progress){
	return progress < 0.5 ? 8 * progress * progress * progress * progress : 1 - pow(-2 * progress + 2, 4) / 2;
}

float EaseInQuint(float progress){
	return progress * progress * progress * progress * progress;
}

float EaseOutQuint(float progress){
	return 1 - pow(1 - progress, 5);
}

float EaseInOutQuint(float progress){
	return progress < 0.5 ? 16 * progress * progress * progress * progress * progress : 1 - pow(-2 * progress + 2, 5) / 2;
}

float EaseInExpo(float progress){
	return progress == 0 ? 0.0 : pow(2, 10 * progress - 10);
}

float EaseOutExpo(float progress){
	return progress == 1 ? 1.0 : 1 - pow(2, -10 * progress);
}

float EaseInOutExpo(float progress){
	return progress == 0
	  ? 0.0
	  : progress == 1
	  ? 1.0
	  : progress < 0.5 ? pow(2, 20 * progress - 10) / 2
	  : (2 - pow(2, -20 * progress + 10)) / 2;
}

float EaseInCirc(float progress){
	return 1 - sqrt(1 - pow(progress, 2));
}

float EaseOutCirc(float progress){
	return sqrt(1 - pow(progress - 1, 2));
}

float EaseInOutCirc(float progress){
	return progress < 0.5
	  ? (1 - sqrt(1 - pow(2 * progress, 2))) / 2
	  : (sqrt(1 - pow(-2 * progress + 2, 2)) + 1) / 2;
}

float EaseInBack(float progress){
	const float c1 = 1.70158;
	const float c3 = c1 + 1;

	return c3 * progress * progress * progress - c1 * progress * progress;
}

float EaseOutBack(float progress){
	const float c1 = 1.70158;
	const float c3 = c1 + 1;

	return 1 + c3 * pow(progress - 1, 3) + c1 * pow(progress - 1, 2);
}

float EaseInOutBack(float progress){
	const float c1 = 1.70158;
	const float c2 = c1 * 1.525;

	return progress < 0.5
	  ? (pow(2 * progress, 2) * ((c2 + 1) * 2 * progress - c2)) / 2
	  : (pow(2 * progress - 2, 2) * ((c2 + 1) * (progress * 2 - 2) + c2) + 2) / 2;
}

float EaseInElastic(float progress){
	const float c4 = (2 * PI) / 3;

	return progress == 0
	  ? 0.0
	  : progress == 1
	  ? 1.0
	  : -pow(2, 10 * progress - 10) * sin((progress * 10 - 10.75) * c4);
}

float EaseOutElastic(float progress){
	const float c4 = (2 * PI) / 3;

	return progress == 0
	  ? 0.0
	  : progress == 1
	  ? 1.0
	  : pow(2, -10 * progress) * sin((progress * 10 - 0.75) * c4) + 1;
}

float EaseInOutElastic(float progress){
	const float c5 = (2 * PI) / 4.5;

	return progress == 0
	  ? 0.0
	  : progress == 1
	  ? 1.0
	  : progress < 0.5
	  ? -(pow(2, 20 * progress - 10) * sin((20 * progress - 11.125) * c5)) / 2
	  : (pow(2, -20 * progress + 10) * sin((20 * progress - 11.125) * c5)) / 2 + 1;
}

float EaseInBounce(float progress){
	return 1 - EaseOutBounce(1 - progress);
}

float EaseOutBounce(float progress){
	const float n1 = 7.5625;
	const float d1 = 2.75;

	if (progress < 1 / d1) {
	    return n1 * progress * progress;
	} else if (progress < 2 / d1) {
	    return n1 * (progress -= 1.5 / d1) * progress + 0.75;
	} else if (progress < 2.5 / d1) {
	    return n1 * (progress -= 2.25 / d1) * progress + 0.9375;
	} else {
	    return n1 * (progress -= 2.625 / d1) * progress + 0.984375;
	}
}

float EaseInOutBounce(float progress){
	return progress < 0.5
	  ? (1 - EaseOutBounce(1 - 2 * progress)) / 2
	  : (1 + EaseOutBounce(2 * progress - 1)) / 2;
}

float ApplyEase(float progress, ease_functions ease){
	switch(ease){
		case easeInSine:
			return EaseInSine(progress);
		case easeOutSine:
			return EaseOutSine(progress);
		case easeInOutSine:
			return EaseInOutSine(progress);
		case easeInQuad:
			return EaseInQuad(progress);
		case easeOutQuad:
			return EaseOutQuad(progress);
		case easeInOutQuad:
			return EaseInOutQuad(progress);
		case easeInCubic:
			return EaseInCubic(progress);
		case easeOutCubic:
			return EaseOutCubic(progress);
		case easeInOutCubic:
			return EaseInOutCubic(progress);
		case easeInQuart:
			return EaseInQuart(progress);
		case easeOutQuart:
			return EaseOutQuart(progress);
		case easeInOutQuart:
			return EaseInOutQuart(progress);
		case easeInQuint:
			return EaseInQuint(progress);
		case easeOutQuint:
			return EaseOutQuint(progress);
		case easeInOutQuint:
			return EaseInOutQuint(progress);
		case easeInExpo:
			return EaseInExpo(progress);
		case easeOutExpo:
			return EaseOutExpo(progress);
		case easeInOutExpo:
			return EaseInOutExpo(progress);
		case easeInCirc:
			return EaseInCirc(progress);
		case easeOutCirc:
			return EaseOutCirc(progress);
		case easeInOutCirc:
			return EaseInOutCirc(progress);
		case easeInBack:
			return EaseInBack(progress);
		case easeOutBack:
			return EaseOutBack(progress);
		case easeInOutBack:
			return EaseInOutBack(progress);
		case easeInElastic:
			return EaseInElastic(progress);
		case easeOutElastic:
			return EaseOutElastic(progress);
		case easeInOutElastic:
			return EaseInOutElastic(progress);
		case easeInBounce:
			return EaseInBounce(progress);
		case easeOutBounce:
			return EaseOutBounce(progress);
		case easeInOutBounce:
			return EaseInOutBounce(progress);
	}
	return progress;
}
