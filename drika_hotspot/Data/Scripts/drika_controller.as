bool animating_camera = false;
array<string> hotspot_ids;
IMGUI@ imGUI;
FontSetup name_font("edosz", 70 , HexColor("#CCCCCC"), true);
FontSetup dialogue_font("arial", 50 , HexColor("#CCCCCC"), true);
FontSetup controls_font("arial", 45 , HexColor("#616161"), true);

void Init(string str){
	@imGUI = CreateIMGUI();
	BuildUI();
}

void SetWindowDimensions(int width, int height){
	BuildUI();
}

void BuildUI(){
	DisposeTextAtlases();
	imGUI.clear();
	imGUI.setHeaderHeight(225);
	imGUI.setFooterHeight(450);
	imGUI.setFooterPanels(500.0f, 500.0f);
	imGUI.setup();

	/* imGUI.getFooter().showBorder(); */

	IMContainer bg_container(0.0, 0.0);
	/* bg_container.showBorder(); */
	IMDivider bg_divider("bg_divider", DOHorizontal);
	bg_divider.setZOrdering(-1);
	bg_container.setElement(bg_divider);

	float bg_alpha = 0.5;
	float bg_height = 350.0;
	float dialogue_height = 450.0;

	IMImage left_fade("Textures/ui/dialogue/dialogue_bg-fade.png");
	left_fade.setSizeX(500.0);
	left_fade.setSizeY(bg_height);
	left_fade.setAlpha(bg_alpha);
	left_fade.setClip(false);
	left_fade.setDisplacementX(0.25);
	bg_divider.append(left_fade);

	IMImage middle_fade("Textures/ui/dialogue/dialogue_bg.png");
	middle_fade.setSizeX(1560.0);
	middle_fade.setSizeY(bg_height);
	middle_fade.setAlpha(bg_alpha);
	middle_fade.setClip(false);
	bg_divider.append(middle_fade);

	IMImage right_fade("Textures/ui/dialogue/dialogue_bg-fade_reverse.png");
	right_fade.setSizeX(500.0);
	right_fade.setSizeY(bg_height);
	right_fade.setAlpha(bg_alpha);
	right_fade.setClip(false);
	right_fade.setDisplacementX(-0.25);
	bg_divider.append(right_fade);

	IMContainer name_container(0.0, 100.0);
	IMDivider name_divider("name_divider", DOHorizontal);
	name_divider.setZOrdering(2);
	/* name_divider.showBorder(); */
	name_divider.setAlignment(CACenter, CACenter);
	name_container.setElement(name_divider);
	IMText name("Turner", name_font);
	name_divider.appendSpacer(30.0);
	name_divider.append(name);
	name_divider.appendSpacer(30.0);

	IMImage name_background("Textures/ui/menus/main/brushStroke.png");
	name_background.setClip(false);
	/* name_background.showBorder(); */

	name_background.setSize(vec2(CalculateTextWidth(name.getText(), name_font.size), 100.0));
	name_container.addFloatingElement(name_background, "name_background", vec2(0, 0), 1);

	imGUI.getFooter().addFloatingElement(name_container, "name_container", vec2(0, 0), 3);
	imGUI.getFooter().addFloatingElement(bg_container, "bg_container", vec2(0.0, 50.0), -1);

	string example_text = "This needs to be here in case the \"Save dialogue?\" popup needs to be \nHello there! [wait 0.2]How can I help you? \nOh, my mistake[wait 0.2] -- I guess I'm talking to myself.";
	array<string> split_text = example_text.split("\n");

	IMDivider dialogue_holder("dialogue_holder", DOHorizontal);
	dialogue_holder.appendSpacer(100.0);
	IMDivider text_divider("text_divider", DOVertical);
	dialogue_holder.append(text_divider);
	text_divider.setAlignment(CALeft, CATop);
	/* text_divider.showBorder(); */
	text_divider.setZOrdering(1);
	/* text_divider.appendSpacer(125.0); */
	for(uint i = 0; i < split_text.size(); i++){
		IMText dialogue_text(split_text[i], dialogue_font);
		text_divider.append(dialogue_text);
	}

	IMContainer controls_container(2400.0, 375.0);
	controls_container.setAlignment(CABottom, CARight);
	IMDivider controls_divider("controls_divider", DOVertical);
	controls_divider.setAlignment(CATop, CALeft);
	controls_divider.setZOrdering(2);
	controls_container.setElement(controls_divider);
	IMText lmb_continue("Left mouse button to continue", controls_font);
	IMText rtn_skip("return to skip", controls_font);
	controls_divider.append(lmb_continue);
	controls_divider.append(rtn_skip);

	imGUI.getFooter().addFloatingElement(controls_container, "controls_container", vec2(0.0, 0.0), -1);
	imGUI.getFooter().setElement(dialogue_holder);
}

float CalculateTextWidth(string text, int font_size){
	uint8 text_length = text.length();
	int lower_case = 0;
	int upper_case = 0;
	for(uint i = 0; i < text_length; i++){
		if(text.substr(i, 1)[0] >= 65 && text.substr(i, 1)[0] <= 90){
			upper_case += 1;
		}else{
			lower_case += 1;
		}
	}
	return (lower_case * font_size * 0.30) + (upper_case * font_size * 1.40);
}

void PostScriptReload(){
	BuildUI();
}

void WriteMusicXML(string music_path, string song_name, string song_path){
	StartWriteFile();
	AddFileString("<?xml version=\"2.0\" ?>\n");
	AddFileString("<Music version=\"1\">\n");

	AddFileString("<Song name=\"" + song_name + "\" type=\"single\" file_path=\"" + song_path + "\" />\n");

	AddFileString("</Music>\n");
	WriteFileToWriteDir(music_path);
}

void DrawGUI(){
	imGUI.render();
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	if(!token_iter.FindNextToken(msg)){
		return;
	}
	string token = token_iter.GetToken(msg);
	if(token == "animating_camera"){
		token_iter.FindNextToken(msg);
		string enable = token_iter.GetToken(msg);
		token_iter.FindNextToken(msg);
		string hotspot_id = token_iter.GetToken(msg);
		if(enable == "true"){
			hotspot_ids.insertLast(hotspot_id);
			animating_camera = true;
		}else{
			for(uint i = 0; i < hotspot_ids.size(); i++){
				if(hotspot_ids[i] == hotspot_id){
					hotspot_ids.removeAt(i);
					i--;
				}
			}
			if(hotspot_ids.size() == 0){
				animating_camera = false;
			}
		}
	}else if(token == "write_music_xml"){
		array<string> lines;
		string xml_content;

		token_iter.FindNextToken(msg);
		string music_path = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		string song_name = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		string song_path = token_iter.GetToken(msg);

		WriteMusicXML(music_path, song_name, song_path);
	}
}

void Update(){
	imGUI.update();
}

bool HasFocus(){
	return false;
}

bool DialogueCameraControl() {
	if(animating_camera){
		return true;
	}else{
		return false;
	}
}
