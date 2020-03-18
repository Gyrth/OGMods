#include "drika_json_functions.as"
#include "drika_animation_group.as"
#include "drika_dialogue_layouts.as"
#include "drika_ui_element.as"
#include "drika_ui_grabber.as"
#include "drika_ui_image.as"
#include "drika_ui_text.as"
#include "drika_ui_font.as"

bool animating_camera = false;
bool has_camera_control = false;
bool show_dialogue = false;
bool showing_choice = false;
array<string> hotspot_ids;
IMGUI@ imGUI;
FontSetup name_font_arial("arial", 70 , HexColor("#CCCCCC"), true);
FontSetup name_font("edosz", 70 , HexColor("#CCCCCC"), true);
FontSetup dialogue_font("arial", 50 , HexColor("#CCCCCC"), true);
FontSetup controls_font("arial", 45 , HexColor("#616161"), true);
array<DrikaAnimationGroup@> all_animations;
vec3 camera_position;
vec3 camera_rotation;
float camera_zoom;
bool fading = false;
float blackout_amount = 0.0;
float starting_fade_amount = 0.0;
float fade_direction = 1.0;
float fade_duration = 0.2;
float fade_timer = 0.0;
float target_fade_to_black = 1.0;
float fade_to_black_duration = 1.0;
bool fade_to_black = false;
array<int> waiting_hotspot_ids;
int dialogue_layout = 0;
bool use_voice_sounds = true;
bool show_names = true;
array<IMContainer@> choice_ui_elements;
array<string> choices;
int selected_choice = 0;
int ui_hotspot_id = -1;
float camera_near_blur = 0.0;
float camera_near_dist = 0.0;
float camera_near_transition = 0.0;
float camera_far_blur = 0.0;
float camera_far_dist = 0.0;
float camera_far_transition = 0.0;
bool enable_look_at_target = false;
bool enable_move_with_target = false;
int track_target_id = -1;
vec3 target_positional_difference = vec3();
vec3 current_camera_position = vec3();
bool camera_settings_changed = false;
vec2 dialogue_size = vec2(2560, 450);

FontSetup default_font("Cella", 70 , HexColor("#CCCCCC"), true);
IMContainer@ dialogue_container;
IMContainer@ image_container;
IMContainer@ text_container;
IMContainer@ grabber_container;
bool editing_ui = false;
array<IMText@> text_elements;
array<DrikaUIElement@> ui_elements;
bool grabber_dragging = false;
DrikaUIGrabber@ current_grabber = null;
DrikaUIElement@ current_ui_element = null;
vec2 click_position;
bool show_grid = true;

class ActorSettings{
	string name = "Default";
	vec4 color = vec4(1.0);
	int voice = 0;
	string avatar_path = "None";

	ActorSettings(){

	}
}

class ReadFileProcess{
	int hotspot_id = -1;
	string data = "";
	string file_path;
	string param_1;
	int param_2;

	ReadFileProcess(int _hotspot_id, string _file_path, string _param_1, int _param_2){
		hotspot_id = _hotspot_id;
		file_path = _file_path;
		param_1 = _param_1;
		param_2 = _param_2;
	}
}

array<string> dialogue_cache;
IMDivider @dialogue_lines_holder_vert;
IMDivider @dialogue_line_holder;
int line_counter = 0;
bool ui_created = false;
string current_actor_name = "Default";
array<ActorSettings@> actor_settings;
ActorSettings@ current_actor_settings = ActorSettings();
array<ReadFileProcess@> read_file_processes;

void Init(string str){
	@imGUI = CreateIMGUI();
	imGUI.setup();
	imGUI.setBackgroundLayers(1);

	imGUI.getMain().setZOrdering(-1);

	@dialogue_container = IMContainer(dialogue_size.x, dialogue_size.y);
	/* dialogue_container.showBorder(); */
	imGUI.getMain().addFloatingElement(dialogue_container, "dialogue_container", vec2(0, 1440 - dialogue_size.y));

	@image_container = IMContainer(2560, 1440);
	imGUI.getMain().addFloatingElement(image_container, "image_container", vec2(0));

	@text_container = IMContainer(2560, 1440);
	imGUI.getMain().addFloatingElement(text_container, "text_container", vec2(0));

	@grabber_container = IMContainer(2560, 1440);
	imGUI.getMain().addFloatingElement(grabber_container, "grabber_container", vec2(0));
}

void SetWindowDimensions(int width, int height){
	if(show_dialogue){
		BuildDialogueUI();
	}
}

void BuildDialogueUI(){
	ui_created = false;
	line_counter = 0;
	DisposeTextAtlases();
	dialogue_container.clear();
	dialogue_container.setSize(dialogue_size);

	CreateNameTag(dialogue_container);
	CreateBackground(dialogue_container);

	switch(dialogue_layout){
		case default_layout:
			DefaultUI(dialogue_container);
			break;
		case simple_layout:
			SimpleUI(dialogue_container);
			break;
		case breath_of_the_wild_layout:
			BreathOfTheWildUI(dialogue_container);
			break;
		case chrono_trigger_layout:
			ChronoTriggerUI(dialogue_container);
			break;
		case fallout_3_green_layout:
			Fallout3UI(dialogue_container);
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
		dialogue_lines_holder_vert.append(choice_container);
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
	parent.setAlignment(CALeft, CACenter);

	IMDivider dialogue_lines_holder_horiz("dialogue_lines_holder_horiz", DOHorizontal);
	dialogue_lines_holder_horiz.appendSpacer(100.0);
	@dialogue_lines_holder_vert = IMDivider("dialogue_lines_holder_vert", DOVertical);
	dialogue_lines_holder_horiz.append(dialogue_lines_holder_vert);
	dialogue_lines_holder_vert.setAlignment(CALeft, CATop);

	@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
	dialogue_lines_holder_vert.append(dialogue_line_holder);
	dialogue_line_holder.setZOrdering(2);

	//Add all the text that has already been added, in case of a refresh.
	for(uint i = 0; i < dialogue_cache.size(); i++){
		IMText dialogue_text(dialogue_cache[i], dialogue_font);
		dialogue_line_holder.append(dialogue_text);

		line_counter += 1;
		@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
		dialogue_lines_holder_vert.append(dialogue_line_holder);
		dialogue_line_holder.setZOrdering(2);
	}

	IMContainer controls_container(2400.0, 375.0);
	controls_container.setAlignment(CABottom, CARight);
	IMDivider controls_divider("controls_divider", DOVertical);
	controls_divider.setAlignment(CATop, CALeft);
	controls_divider.setZOrdering(1);
	controls_container.setElement(controls_divider);
	IMText lmb_continue("Left mouse button to continue", controls_font);
	IMText rtn_skip("return to skip", controls_font);
	controls_divider.append(lmb_continue);
	controls_divider.append(rtn_skip);

	parent.addFloatingElement(controls_container, "controls_container", vec2(0.0, 0.0), -1);
	parent.setElement(dialogue_lines_holder_horiz);
}

void SimpleUI(IMContainer@ parent){
	parent.setAlignment(CACenter, CACenter);
	/* parent.showBorder(); */

	IMDivider dialogue_lines_holder_horiz("dialogue_lines_holder_horiz", DOHorizontal);
	dialogue_lines_holder_horiz.setAlignment(CACenter, CATop);
	@dialogue_lines_holder_vert = IMDivider("dialogue_lines_holder_vert", DOVertical);
	dialogue_lines_holder_horiz.append(dialogue_lines_holder_vert);
	dialogue_lines_holder_vert.setAlignment(CACenter, CATop);

	@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
	dialogue_lines_holder_vert.append(dialogue_line_holder);
	dialogue_line_holder.setZOrdering(2);

	//Add all the text that has already been added, in case of a refresh.
	for(uint i = 0; i < dialogue_cache.size(); i++){
		IMText dialogue_text(dialogue_cache[i], dialogue_font);
		dialogue_line_holder.append(dialogue_text);

		line_counter += 1;
		@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
		dialogue_lines_holder_vert.append(dialogue_line_holder);
		dialogue_line_holder.setZOrdering(2);
	}

	parent.setElement(dialogue_lines_holder_horiz);
}

void BreathOfTheWildUI(IMContainer@ parent){
	parent.setAlignment(CACenter, CACenter);
	/* parent.showBorder(); */
	parent.setSizeY(400.0);

	IMDivider dialogue_lines_holder_horiz("dialogue_lines_holder_horiz", DOHorizontal);
	dialogue_lines_holder_horiz.setAlignment(CACenter, CATop);
	@dialogue_lines_holder_vert = IMDivider("dialogue_lines_holder_vert", DOVertical);
	dialogue_lines_holder_horiz.append(dialogue_lines_holder_vert);
	dialogue_lines_holder_vert.setAlignment(CACenter, CATop);

	@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
	dialogue_lines_holder_vert.append(dialogue_line_holder);
	dialogue_line_holder.setZOrdering(2);

	//Add all the text that has already been added, in case of a refresh.
	for(uint i = 0; i < dialogue_cache.size(); i++){
		IMText dialogue_text(dialogue_cache[i], dialogue_font);
		dialogue_line_holder.append(dialogue_text);

		line_counter += 1;
		@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
		dialogue_lines_holder_vert.append(dialogue_line_holder);
		dialogue_line_holder.setZOrdering(2);
	}

	parent.setElement(dialogue_lines_holder_horiz);
}

void ChronoTriggerUI(IMContainer@ parent){
	parent.setAlignment(CACenter, CABottom);
	/* parent.showBorder(); */
	parent.setSizeY(450.0);

	IMContainer dialogue_holder(1500, 300);
	dialogue_holder.setAlignment(CALeft, CATop);
	/* dialogue_holder.showBorder(); */

	IMDivider dialogue_lines_holder_horiz("dialogue_lines_holder_horiz", DOHorizontal);
	dialogue_holder.setElement(dialogue_lines_holder_horiz);
	dialogue_lines_holder_horiz.setAlignment(CACenter, CATop);
	@dialogue_lines_holder_vert = IMDivider("dialogue_lines_holder_vert", DOVertical);
	dialogue_lines_holder_horiz.append(dialogue_lines_holder_vert);
	dialogue_lines_holder_vert.setAlignment(CALeft, CATop);

	@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
	dialogue_lines_holder_vert.append(dialogue_line_holder);
	dialogue_line_holder.setZOrdering(2);

	//Add all the text that has already been added, in case of a refresh.
	for(uint i = 0; i < dialogue_cache.size(); i++){
		IMText dialogue_text(dialogue_cache[i], dialogue_font);
		dialogue_line_holder.append(dialogue_text);

		line_counter += 1;
		@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
		dialogue_lines_holder_vert.append(dialogue_line_holder);
		dialogue_line_holder.setZOrdering(2);
	}

	parent.setElement(dialogue_holder);
}

void Fallout3UI(IMContainer@ parent){
	parent.setAlignment(CACenter, CABottom);
	/* parent.showBorder(); */
	parent.setSizeY(450.0);

	IMContainer dialogue_holder(1400, 400);
	dialogue_holder.setAlignment(CALeft, CATop);
	/* dialogue_holder.showBorder(); */

	IMDivider dialogue_lines_holder_horiz("dialogue_lines_holder_horiz", DOHorizontal);
	dialogue_holder.setElement(dialogue_lines_holder_horiz);
	dialogue_lines_holder_horiz.setAlignment(CACenter, CATop);
	@dialogue_lines_holder_vert = IMDivider("dialogue_lines_holder_vert", DOVertical);
	dialogue_lines_holder_horiz.append(dialogue_lines_holder_vert);
	dialogue_lines_holder_vert.setAlignment(CALeft, CATop);

	@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
	dialogue_lines_holder_vert.append(dialogue_line_holder);
	dialogue_line_holder.setZOrdering(2);

	//Add all the text that has already been added, in case of a refresh.
	for(uint i = 0; i < dialogue_cache.size(); i++){
		IMText dialogue_text(dialogue_cache[i], dialogue_font);
		dialogue_line_holder.append(dialogue_text);

		line_counter += 1;
		@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
		dialogue_lines_holder_vert.append(dialogue_line_holder);
		dialogue_line_holder.setZOrdering(2);
	}

	parent.setElement(dialogue_holder);
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

	float bg_alpha = 0.5;
	float bg_height = 350.0;

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

	parent.addFloatingElement(bg_container, "bg_container", vec2(0.0, 50.0), -1);
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

void CreateNameTag(IMContainer@ parent){
	if(!show_dialogue || !show_names || showing_choice){
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

	IMText name(current_actor_settings.name, name_font);
	name_divider.appendSpacer(50.0);
	name_divider.append(name);
	name_divider.appendSpacer(50.0);
	name.setColor(current_actor_settings.color);

	IMImage name_background("Textures/ui/menus/main/brushStroke.png");
	name_background.setClip(false);
	parent.addFloatingElement(name_container, "name_container", vec2(0, 0), 3);

	imGUI.update();
	name_background.setSize(name_container.getSize());
	name_container.addFloatingElement(name_background, "name_background", vec2(0, 0), 1);
	name_background.setZOrdering(1);
}

void SimpleNameTag(IMContainer@ parent){
	//Remove any nametag that's already there.
	parent.removeElement("nametag_container");

	IMContainer nametag_container(0.0, 0.0);
	IMDivider nametag_divider("nametag_divider", DOHorizontal);
	nametag_container.setElement(nametag_divider);
	nametag_divider.setAlignment(CACenter, CATop);

	if(current_actor_settings.avatar_path != "None"){
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

	IMText name(current_actor_settings.name, name_font_arial);
	name_divider.appendSpacer(60.0);
	name_divider.append(name);
	name_divider.appendSpacer(60.0);
	name.setColor(current_actor_settings.color);

	IMImage name_background("Textures/dialogue_bg_nametag_faded.png");
	name_background.setClip(false);
	name_background.setAlpha(0.75);
	parent.addFloatingElement(nametag_container, "nametag_container", vec2(300, -50), 3);

	imGUI.update();
	name_background.setSize(name_container.getSize());
	name_container.addFloatingElement(name_background, "name_background", vec2(0, 0), 1);
	name_background.setZOrdering(1);
}

void BreathOfTheWildNameTag(IMContainer@ parent){
	//Remove any nametag that's already there.
	parent.removeElement("name_container");

	IMContainer name_container(0.0, 100.0);
	IMDivider name_divider("name_divider", DOHorizontal);
	name_divider.setZOrdering(3);
	name_divider.setAlignment(CACenter, CACenter);
	name_container.setElement(name_divider);

	if(current_actor_settings.avatar_path != "None"){
		IMImage avatar_image(current_actor_settings.avatar_path);
		avatar_image.setSize(vec2(350, 350));
		avatar_image.setClip(false);
		name_container.addFloatingElement(avatar_image, "avatar", vec2(-500, 50), 3);
	}

	IMText name(current_actor_settings.name, dialogue_font);
	name_divider.appendSpacer(30.0);
	name_divider.append(name);
	name_divider.appendSpacer(30.0);
	name.setColor(current_actor_settings.color);

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

	if(current_actor_settings.avatar_path != "None"){
		IMImage avatar_image(current_actor_settings.avatar_path);
		avatar_image.setSize(vec2(350, 350));
		avatar_image.setClip(false);
		name_container.addFloatingElement(avatar_image, "avatar", vec2(-450, 25), 3);
	}

	IMText name(current_actor_settings.name + " : ", dialogue_font);
	name_divider.appendSpacer(30.0);
	name_divider.append(name);
	name_divider.appendSpacer(30.0);
	name.setColor(current_actor_settings.color);

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

	if(current_actor_settings.avatar_path != "None"){
		IMImage avatar_image(current_actor_settings.avatar_path);
		avatar_image.setSize(vec2(350, 350));
		avatar_image.setClip(false);
		name_container.addFloatingElement(avatar_image, "avatar", vec2(-1050, 100), 3);
	}

	IMText name(current_actor_settings.name, dialogue_font);
	name_divider.append(name);
	name.setColor(current_actor_settings.color);

	parent.addFloatingElement(name_container, "name_container", vec2(0.0, -dialogue_font.size), 3);

}

void PostScriptReload(){
	if(show_dialogue){
		BuildDialogueUI();
	}
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
	HUDImage @blackout_image = hud.AddImage();
	blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
	blackout_image.position.y = (GetScreenWidth() + GetScreenHeight()) * -1.0f;
	blackout_image.position.x = (GetScreenWidth() + GetScreenHeight()) * -1.0f;
	blackout_image.position.z = -2.0f;
	blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight()) * 2.0f;
	blackout_image.color = vec4(0.0f, 0.0f, 0.0f, blackout_amount);
	if(editing_ui){
		DrawMouseBlockContainer();
		DrawGrid();
	}
}

void DrawMouseBlockContainer(){
	ImGui_PushStyleColor(ImGuiCol_WindowBg, vec4(0.0f, 0.0f, 0.0f, 0.0f));
	ImGui_Begin("MouseBlockContainer", editing_ui, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoBringToFrontOnFocus);
	UpdateGrabber();
	ImGui_PopStyleColor(1);
	ImGui_SetWindowPos("MouseBlockContainer", vec2(0,0));
	ImGui_SetWindowSize("MouseBlockContainer", vec2(GetScreenWidth(), GetScreenHeight()));
	ImGui_End();
}

int ui_snap_scale = 20;

void DrawGrid(){
	if(!show_grid){
		return;
	}
	vec2 vertical_position = vec2(0.0, 0.0);
	vec2 horizontal_position = vec2(0.0, 0.0);
	int nr_horizontal_lines = int(ceil(screenMetrics.screenSize.y / (ui_snap_scale * screenMetrics.GUItoScreenYScale)));
	int nr_vertical_lines = int(ceil(screenMetrics.screenSize.x / (ui_snap_scale * screenMetrics.GUItoScreenXScale))) + 1;
	vec4 line_color = vec4(0.25, 0.25, 0.25, 1.0);
	float line_width = 1.0;
	float thick_line_width = 3.0;

	for(int i = 0; i < nr_vertical_lines; i++){
		bool thick_line = i % 10 == 0;

		imGUI.drawBox(vertical_position, vec2(thick_line?thick_line_width:line_width, screenMetrics.screenSize.y), line_color, 0, false);
		vertical_position += vec2((ui_snap_scale * screenMetrics.GUItoScreenXScale), 0.0);
	}

	for(int i = 0; i < nr_horizontal_lines; i++){
		bool thick_line = i % 10 == 0;
		imGUI.drawBox(horizontal_position, vec2(screenMetrics.screenSize.x, thick_line?thick_line_width:line_width), line_color, 0, false);
		horizontal_position += vec2(0.0, (ui_snap_scale * screenMetrics.GUItoScreenYScale));
	}
}

void ReceiveMessage(string msg){
	TokenIterator token_iter;
	token_iter.Init();
	if(!token_iter.FindNextToken(msg)){
		return;
	}
	string token = token_iter.GetToken(msg);

	/* Log(warning, token); */
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
	}else if(token == "reset"){
		has_camera_control = false;
		fade_timer = 0.0;
		camera_near_blur = 0.0;
		camera_near_dist = 0.0;
		camera_near_transition = 0.0;
		camera_far_blur = 0.0;
		camera_far_dist = 0.0;
		camera_far_transition = 0.0;
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
	}else if(token == "drika_dialogue_hide"){
		show_dialogue = false;
		showing_choice = false;
		ui_hotspot_id = -1;
		dialogue_container.clear();
	}else if(token == "drika_dialogue_add_say"){
		token_iter.FindNextToken(msg);
		string actor_name = token_iter.GetToken(msg);

		if(!show_dialogue){
			show_dialogue = true;
			BuildDialogueUI();
		}

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

			CreateNameTag(dialogue_container);
			CreateBackground(dialogue_container);
		}

		PlayLineContinueSound();

		token_iter.FindNextToken(msg);
		string text = token_iter.GetToken(msg);

		array<string> split_text = text.split(" ");

		for(uint i = 0; i < split_text.size(); i++){
			if(split_text[i] != "\n"){
				IMText dialogue_text(split_text[i] + " ", dialogue_font);
				if(dialogue_cache.size() == 0){
					dialogue_cache.insertLast("");
				}
				dialogue_cache[dialogue_cache.size() - 1] += split_text[i] + " ";
				dialogue_text.addUpdateBehavior(IMFadeIn(250, inSineTween ), "");

				dialogue_line_holder.append(dialogue_text);
			}
			imGUI.update();

			if(dialogue_line_holder.getSizeX() > 1450.0 || split_text[i] == "\n"){
				line_counter += 1;
				dialogue_cache.insertLast("");
				@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
				dialogue_lines_holder_vert.append(dialogue_line_holder);
				dialogue_line_holder.setZOrdering(2);
			}
		}
	}else if(token == "drika_dialogue_clear_say"){
		choices.resize(0);
		dialogue_cache.resize(0);
		line_counter = 0;
		dialogue_cache.insertLast("");

		if(show_dialogue){
			dialogue_lines_holder_vert.clear();
			@dialogue_line_holder = IMDivider("dialogue_line_holder" + line_counter, DOHorizontal);
			dialogue_lines_holder_vert.append(dialogue_line_holder);
			dialogue_line_holder.setZOrdering(2);
		}
	}else if(token == "drika_dialogue_set_actor_settings"){
		token_iter.FindNextToken(msg);
		string actor_name = token_iter.GetToken(msg);

		vec4 color;
		token_iter.FindNextToken(msg);
		color.x = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		color.y = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		color.z = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		color.a = atof(token_iter.GetToken(msg));

		token_iter.FindNextToken(msg);
		int voice = atoi(token_iter.GetToken(msg));

		token_iter.FindNextToken(msg);
		string avatar_path = token_iter.GetToken(msg);

		if(avatar_path != "None"){
			array<string> split_path = avatar_path.split("/");
			//Remove the Data/ in the beginning of the path.
			split_path.removeAt(0);
			avatar_path = join(split_path, "/");
		}

		bool settings_found = false;
		for(uint i = 0; i < actor_settings.size(); i++){
			if(actor_settings[i].name == actor_name){
				settings_found = true;
				actor_settings[i].voice = voice;
				actor_settings[i].color = color;
				actor_settings[i].avatar_path = avatar_path;
				break;
			}
		}

		if(!settings_found){
			ActorSettings new_settings();
			new_settings.name = actor_name;
			new_settings.voice = voice;
			new_settings.color = color;
			new_settings.avatar_path = avatar_path;
			actor_settings.insertLast(@new_settings);
		}
	}else if(token == "drika_dialogue_test_voice"){
		token_iter.FindNextToken(msg);
		int test_voice = atoi(token_iter.GetToken(msg));
		PlayLineContinueSound(test_voice);
	}else if(token == "drika_dialogue_skip"){
		PlayLineStartSound();
	}else if(token == "drika_dialogue_get_animations"){
		token_iter.FindNextToken(msg);
		int hotspot_id = atoi(token_iter.GetToken(msg));

		if(all_animations.size() == 0){
			ReadAnimationList();
		}
		Object@ hotspot_obj = ReadObjectFromID(hotspot_id);
		for(uint i = 0; i < all_animations.size(); i++){
			hotspot_obj.ReceiveScriptMessage("drika_dialogue_add_animation_group " + "\"" + all_animations[i].name + "\"");

			for(uint j = 0; j < all_animations[i].animations.size(); j++){
				hotspot_obj.ReceiveScriptMessage("drika_dialogue_add_animation " + all_animations[i].animations[j]);
			}
		}
		hotspot_obj.ReceiveScriptMessage("drika_dialogue_send_done");
	}else if(token == "drika_dialogue_set_camera_position"){
		token_iter.FindNextToken(msg);
		camera_rotation.x = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		camera_rotation.y = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		camera_rotation.z = atof(token_iter.GetToken(msg));

		token_iter.FindNextToken(msg);
		camera_position.x = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		camera_position.y = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		camera_position.z = atof(token_iter.GetToken(msg));

		token_iter.FindNextToken(msg);
		camera_zoom = atof(token_iter.GetToken(msg));

		token_iter.FindNextToken(msg);
		enable_look_at_target = token_iter.GetToken(msg) == "true";

		token_iter.FindNextToken(msg);
		enable_move_with_target = token_iter.GetToken(msg) == "true";

		if(enable_look_at_target || enable_move_with_target){
			token_iter.FindNextToken(msg);
			track_target_id = atoi(token_iter.GetToken(msg));

			if(track_target_id != -1 && ObjectExists(track_target_id)){
				Object@ track_target = ReadObjectFromID(track_target_id);
				vec3 target_location;
				if(track_target.GetType() == _movement_object){
					MovementObject@ char = ReadCharacterID(track_target_id);
					target_location = char.rigged_object().GetAvgIKChainPos("torso");
				}else if(track_target.GetType() == _item_object){
					ItemObject@ item = ReadItemID(track_target_id);
					target_location = item.GetPhysicsPosition();
				}
				target_positional_difference = camera_position - target_location;
			}
		}

		current_camera_position = camera_position;
		camera_settings_changed = true;
	}else if(token == "drika_dialogue_end"){
		show_dialogue = false;
		fade_to_black = false;
		showing_choice = false;
		has_camera_control = false;
		ui_hotspot_id = -1;
		dialogue_container.clear();
	}else if(token == "drika_dialogue_fade_out_in"){
		token_iter.FindNextToken(msg);
		int hotspot_id = atoi(token_iter.GetToken(msg));
		waiting_hotspot_ids.insertLast(hotspot_id);

		fading = true;
		fade_direction = 1.0;
	}else if(token == "drika_dialogue_fade_to_black"){
		token_iter.FindNextToken(msg);
		target_fade_to_black = atof(token_iter.GetToken(msg));
		starting_fade_amount = blackout_amount;

		token_iter.FindNextToken(msg);
		fade_to_black_duration = atof(token_iter.GetToken(msg));

		fade_to_black = true;
	}else if(token == "drika_dialogue_clear_fade_to_black"){
		fade_timer = 0.0;
		blackout_amount = 0.0;
		fade_to_black = false;
	}else if(token == "drika_dialogue_set_settings"){
		token_iter.FindNextToken(msg);
		dialogue_layout = atoi(token_iter.GetToken(msg));

		token_iter.FindNextToken(msg);
		string new_font_path = token_iter.GetToken(msg);
		array<string> new_font_path_split = new_font_path.split("/");
		string new_font_file = new_font_path_split[new_font_path_split.size() - 1];
		string dialogue_text_font = new_font_file.substr(0, new_font_file.length() - 4);

		token_iter.FindNextToken(msg);
		int dialogue_text_size = atoi(token_iter.GetToken(msg));

		vec4 dialogue_text_color;
		token_iter.FindNextToken(msg);
		dialogue_text_color.x = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		dialogue_text_color.y = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		dialogue_text_color.z = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		dialogue_text_color.a = atof(token_iter.GetToken(msg));

		token_iter.FindNextToken(msg);
		bool dialogue_text_shadow = token_iter.GetToken(msg) == "true";

		token_iter.FindNextToken(msg);
		use_voice_sounds = token_iter.GetToken(msg) == "true";

		token_iter.FindNextToken(msg);
		show_names = token_iter.GetToken(msg) == "true";

		dialogue_font = FontSetup(dialogue_text_font, dialogue_text_size, dialogue_text_color, dialogue_text_shadow);
	}else if(token == "drika_read_file"){
		token_iter.FindNextToken(msg);
		int hotspot_id = atoi(token_iter.GetToken(msg));

		token_iter.FindNextToken(msg);
		string file_path = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		string param_1 = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		int param_2 = atoi(token_iter.GetToken(msg));

		read_file_processes.insertLast(ReadFileProcess(hotspot_id, file_path, param_1, param_2));
	}else if(token == "drika_dialogue_choice"){
		token_iter.FindNextToken(msg);
		int hotspot_id = atoi(token_iter.GetToken(msg));

		array<string> lines;

		while(token_iter.FindNextToken(msg)){
			lines.insertLast(token_iter.GetToken(msg));
		}

		selected_choice = 0;
		choices = lines;

		if(!show_dialogue){

			if(!EditorModeActive()){
				SetGrabMouse(false);
			}

			show_dialogue = true;
			showing_choice = true;
			ui_hotspot_id = hotspot_id;
			BuildDialogueUI();
		}

	}else if(token == "drika_dialogue_choice_select"){
		token_iter.FindNextToken(msg);
		int new_selected_choice = atoi(token_iter.GetToken(msg));

		if(new_selected_choice != selected_choice){
			SelectChoice(new_selected_choice);
		}
	}else if(token == "drika_set_dof"){
		token_iter.FindNextToken(msg);
		camera_near_blur = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		camera_near_dist = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		camera_near_transition = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		camera_far_blur = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		camera_far_dist = atof(token_iter.GetToken(msg));
		token_iter.FindNextToken(msg);
		camera_far_transition = atof(token_iter.GetToken(msg));
	}else if(token == "drika_set_fov"){
		token_iter.FindNextToken(msg);
		camera_zoom = atof(token_iter.GetToken(msg));
	}else if(token == "request_preview_dof"){
		camera.SetDOF(camera_near_blur, camera_near_dist, camera_near_transition, camera_far_blur, camera_far_dist, camera_far_transition);
	}else if(token == "drika_export_to_file"){
		token_iter.FindNextToken(msg);
		string path = token_iter.GetToken(msg);
		string content = "";

		while(token_iter.FindNextToken(msg)){
			content += token_iter.GetToken(msg);
		}
        StartWriteFile();
		AddFileString(content);
        WriteFileKeepBackup(path);
	}else if(token == "drika_import_from_file"){
		token_iter.FindNextToken(msg);
		int hotspot_id = atoi(token_iter.GetToken(msg));

		token_iter.FindNextToken(msg);
		string file_path = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		string param_1 = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		int param_2 = atoi(token_iter.GetToken(msg));

		read_file_processes.insertLast(ReadFileProcess(hotspot_id, file_path, param_1, param_2));
	}else if(token == "drika_edit_ui"){
		token_iter.FindNextToken(msg);
		string ui_element_identifier = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		editing_ui = token_iter.GetToken(msg) == "true";

		if(editing_ui){
			token_iter.FindNextToken(msg);
			ui_hotspot_id = atoi(token_iter.GetToken(msg));

			token_iter.FindNextToken(msg);
			show_grid = token_iter.GetToken(msg) == "true";

			token_iter.FindNextToken(msg);
			ui_snap_scale = max(5, atoi(token_iter.GetToken(msg)));
		}else{
			ui_hotspot_id = -1;
		}
	}else if(token == "drika_ui_add_image"){
		token_iter.FindNextToken(msg);
		string json_string = token_iter.GetToken(msg);

		JSON data;

		if(!data.parseString(json_string)){
			Log(warning, "Unable to parse the JSON in the UI JSON Data!");
		}else{
			JSONValue json_data = data.getRoot();
			DrikaUIImage image(json_data);
			@current_ui_element = @image;
			ui_elements.insertLast(image);
		}
	}else if(token == "drika_ui_add_text"){
		token_iter.FindNextToken(msg);
		string json_string = token_iter.GetToken(msg);

		JSON data;

		if(!data.parseString(json_string)){
			Log(warning, "Unable to parse the JSON in the UI JSON Data!");
		}else{
			JSONValue json_data = data.getRoot();
			DrikaUIText text(json_data);
			@current_ui_element = @text;
			ui_elements.insertLast(text);
		}
	}else if(token == "drika_ui_add_font"){
		token_iter.FindNextToken(msg);
		string json_string = token_iter.GetToken(msg);

		JSON data;

		if(!data.parseString(json_string)){
			Log(warning, "Unable to parse the JSON in the UI JSON Data!");
		}else{
			JSONValue json_data = data.getRoot();
			DrikaUIFont font(json_data);
			@current_ui_element = @font;
			ui_elements.insertLast(font);
		}
	}else if(token == "drika_ui_remove_element"){
		token_iter.FindNextToken(msg);
		string ui_element_identifier = token_iter.GetToken(msg);

		int index = GetUIElementIndex(ui_element_identifier);
		if(index != -1){
			ui_elements[index].Delete();
			ui_elements.removeAt(index);
		}
		@current_grabber = null;
	}else if(token == "drika_ui_set_editing"){
		token_iter.FindNextToken(msg);
		string ui_element_identifier = token_iter.GetToken(msg);

		token_iter.FindNextToken(msg);
		bool editing = token_iter.GetToken(msg) == "true";

		@current_ui_element = GetUIElement(ui_element_identifier);
		current_ui_element.SetEditing(editing);
	}else if(token == "drika_ui_instruction"){
		token_iter.FindNextToken(msg);
		string ui_element_identifier = token_iter.GetToken(msg);
		array<string> instruction;

		while(token_iter.FindNextToken(msg)){
			instruction.insertLast(token_iter.GetToken(msg));
		}

		GetUIElement(ui_element_identifier).ReadUIInstruction(instruction);
	}else if(token == "drika_set_show_grid"){
		token_iter.FindNextToken(msg);
		show_grid = token_iter.GetToken(msg) == "true";
	}else if(token == "drika_set_ui_snap_scale"){
		token_iter.FindNextToken(msg);
		ui_snap_scale = max(5, atoi(token_iter.GetToken(msg)));
	}
}

void SendUIInstruction(string param_1, array<string> params){
	if(ui_hotspot_id != -1){
		Object@ hotspot_obj = ReadObjectFromID(ui_hotspot_id);

		string msg = "drika_ui_instruction ";
		msg += param_1 + " ";
		for(uint i = 0; i < params.size(); i++){
			msg += params[i] + " ";
		}

		hotspot_obj.ReceiveScriptMessage(msg);
	}
}

DrikaUIElement@ GetUIElement(string identifier){
	for(uint i = 0; i < ui_elements.size(); i++){
		if(ui_elements[i].ui_element_identifier == identifier){
			return ui_elements[i];
		}
	}
	return @DrikaUIElement();
}

int GetUIElementIndex(string identifier){
	for(uint i = 0; i < ui_elements.size(); i++){
		if(ui_elements[i].ui_element_identifier == identifier){
			return i;
		}
	}
	return -1;
}

void SelectChoice(int new_selected_choice){
	if(new_selected_choice != selected_choice){
		choice_ui_elements[selected_choice].showBorder(false);
		choice_ui_elements[selected_choice].removeElement("bg");
	}
	selected_choice = new_selected_choice;
	choice_ui_elements[selected_choice].showBorder(true);

	vec4 background_color = dialogue_font.color;
	background_color.a = 0.15f;
	IMImage background_image("Textures/ui/whiteblock.tga");
	background_image.setClip(true);
	background_image.setSize(vec2(1500.0 + 40.0, dialogue_font.size + 40.0));
	background_image.setEffectColor(background_color);
	choice_ui_elements[selected_choice].addFloatingElement(background_image, "bg", vec2(-20.0));
}

void ReadAnimationList(){
	JSON file;
	file.parseFile("Data/Scripts/drika_dialogue_animation_list.json");
	JSONValue root = file.getRoot();
	array<string> list_groups = root.getMemberNames();
	array<string> active_mods;

	array<ModID> mod_ids = GetActiveModSids();
	for(uint i = 0; i < mod_ids.size(); i++){
		active_mods.insertLast(ModGetID(mod_ids[i]));
	}

	for(uint i = 0; i < list_groups.size(); i++){
		//Skip this mod if it's not active
		if(active_mods.find(root[list_groups[i]]["Mod ID"].asString()) == -1){
			continue;
		}
		DrikaAnimationGroup new_group(list_groups[i]);
		JSONValue animation_list = root[list_groups[i]]["Animations"];
		for(uint j = 0; j < animation_list.size(); j++){
			string new_animation = animation_list[j].asString();
			if(FileExists(new_animation)){
				//This animation exists in the game fils so add it to the animation group.
				new_group.AddAnimation(new_animation);
			}
		}
		new_group.SortAlphabetically();
		all_animations.insertLast(@new_group);
	}
}

void Update(){

	while(imGUI.getMessageQueueSize() > 0 ){
        IMMessage@ message = imGUI.getNextMessage();

		if(ui_hotspot_id != -1){
			Object@ hotspot_obj = ReadObjectFromID(ui_hotspot_id);
			if(message.name == "drika_dialogue_choice_select"){
				hotspot_obj.ReceiveScriptMessage("drika_ui_event drika_dialogue_choice_select " + message.getInt(0));
			}else if(message.name == "drika_dialogue_choice_pick"){
				hotspot_obj.ReceiveScriptMessage("drika_ui_event drika_dialogue_choice_pick " + message.getInt(0));
			}else if(message.name == "grabber_activate"){
				if(!grabber_dragging){
					@current_grabber = current_ui_element.GetGrabber(message.getString(0));
				}
			}else if(message.name == "grabber_deactivate"){
				if(!grabber_dragging){
					@current_grabber = null;
				}
			}
		}
	}

	imGUI.update();
	SetCameraPosition();
	UpdateReadFileProcesses();
	if(fading){
		blackout_amount = fade_timer / fade_duration;
		if(fade_direction == 1.0){
			if(fade_timer >= fade_duration){
				//Screen has faded all the way to black.
				has_camera_control = !has_camera_control;
				MessageWaitingForFadeOut();
				fade_direction = -1.0;
			}
			fade_timer += time_step;
		}else{
			if(fade_timer <= 0.0){
				//Screen has faded all the way from black to clear.
				fading = false;
			}
			fade_timer -= time_step;
		}
	}else if(fade_to_black){
		blackout_amount = mix(starting_fade_amount, target_fade_to_black, fade_timer / max(0.0001, fade_to_black_duration));
		if(fade_timer >= fade_to_black_duration){
			fade_to_black = false;
			fade_timer = fade_duration;
			return;
		}
		fade_timer += time_step;
	}
}

void UpdateGrabber(){
	if(grabber_dragging){
		if(!ImGui_IsMouseDown(0)){
			grabber_dragging = false;
		}else{
			vec2 current_grabber_position = current_grabber.GetPosition();
			vec2 new_position = current_grabber_position + (imGUI.guistate.mousePosition - click_position);

			bool round_x_direction = (new_position.x % ui_snap_scale > (ui_snap_scale / 2.0))?true:false;
			bool round_y_direction = (new_position.y % ui_snap_scale > (ui_snap_scale / 2.0))?true:false;
			vec2 new_snap_position;
			new_snap_position.x = round_x_direction?ceil(new_position.x / ui_snap_scale):floor(new_position.x / ui_snap_scale);
			new_snap_position.y = round_y_direction?ceil(new_position.y / ui_snap_scale):floor(new_position.y / ui_snap_scale);
			new_snap_position *= ui_snap_scale;

			if(current_grabber_position != new_snap_position){
				vec2 difference = (new_snap_position - current_grabber_position);
				int direction_x = (difference.x > 0.0) ? 1 : -1;
				int direction_y = (difference.y > 0.0) ? 1 : -1;

				if(current_grabber.grabber_type == scaler){
					if(current_grabber_position.x != new_snap_position.x){
						current_ui_element.AddSize(ivec2(int(difference.x), 0), current_grabber.direction_x, current_grabber.direction_y);
						click_position.x += int(difference.x);
					}
					if(current_grabber_position.y != new_snap_position.y){
						current_ui_element.AddSize(ivec2(0, int(difference.y)), current_grabber.direction_x, current_grabber.direction_y);
						click_position.y += int(difference.y);
					}
				}else if(current_grabber.grabber_type == mover){
					if(current_grabber_position.x != new_snap_position.x){
						current_ui_element.AddPosition(ivec2(int(difference.x), 0));
						click_position.x += int(difference.x);
					}
					if(current_grabber_position.y != new_snap_position.y){
						current_ui_element.AddPosition(ivec2(0, int(difference.y)));
						click_position.y += int(difference.y);
					}
				}
			}
		}
	}else{
		if(ImGui_IsMouseDown(0) && @current_grabber != null && ImGui_IsWindowHovered()){
			click_position = imGUI.guistate.mousePosition;
			grabber_dragging = true;
		}
	}
}

void UpdateReadFileProcesses(){
	if(read_file_processes.size() > 0){
		if(LoadFile(read_file_processes[0].file_path)){
			while(true){
				string line = GetFileLine();
				if(line == "end"){
					break;
				}else{
					read_file_processes[0].data += line + "\n";
				}
			}
			Object@ hotspot_obj = ReadObjectFromID(read_file_processes[0].hotspot_id);
			read_file_processes[0].data = join(read_file_processes[0].data.split("\""), "\\\"");
			hotspot_obj.ReceiveScriptMessage("drika_read_file " + " " + read_file_processes[0].param_1 + " " + read_file_processes[0].param_2 + "\"" + read_file_processes[0].data + "\"");
		}else{
			Log(error, "Error loading file: " + read_file_processes[0].file_path);
		}

		read_file_processes.removeAt(0);
	}
}

int update_counter = 0;

void SetCameraPosition(){
	if((animating_camera || has_camera_control) && !EditorModeActive()){

		if(camera_settings_changed){
			camera.SetPos(camera_position);
			camera.SetXRotation(camera_rotation.x);
			camera.SetYRotation(camera_rotation.y);
			camera.SetZRotation(camera_rotation.z);
			camera.CalcFacing();

			camera.FixDiscontinuity();
			camera_settings_changed = false;

			return;
		}

		if(enable_look_at_target){
			if(track_target_id != -1 && ObjectExists(track_target_id)){
				Object@ track_target = ReadObjectFromID(track_target_id);
				if(track_target.GetType() == _movement_object){
					MovementObject@ char = ReadCharacterID(track_target_id);
					SmoothCameraLookAt(char.rigged_object().GetAvgIKChainPos("torso"));
				}else if(track_target.GetType() == _item_object){
					ItemObject@ item = ReadItemID(track_target_id);
					SmoothCameraLookAt(item.GetPhysicsPosition());
				}
			}
		}else{
			camera.SetXRotation(camera_rotation.x);
			camera.SetYRotation(camera_rotation.y);
			camera.SetZRotation(camera_rotation.z);
		}

		if(enable_move_with_target){
			if(track_target_id != -1 && ObjectExists(track_target_id)){
				Object@ track_target = ReadObjectFromID(track_target_id);
				if(track_target.GetType() == _movement_object){
					MovementObject@ char = ReadCharacterID(track_target_id);
					SmoothCameraMoveWith(char.rigged_object().GetAvgIKChainPos("torso"));
				}else if(track_target.GetType() == _item_object){
					ItemObject@ item = ReadItemID(track_target_id);
					SmoothCameraMoveWith(item.GetPhysicsPosition());
				}
			}
		}else{
			camera.SetPos(camera_position);
			current_camera_position = camera_position;
		}

		camera.SetDistance(0.0f);
		camera.SetFOV(camera_zoom);
		camera.SetDOF(camera_near_blur, camera_near_dist, camera_near_transition, camera_far_blur, camera_far_dist, camera_far_transition);
		UpdateListener(camera_position, vec3(0.0f), camera.GetFacing(), camera.GetUpVector());
		if(!showing_choice){
			SetGrabMouse(true);
		}
	}

}

void SmoothCameraMoveWith(vec3 target_location){
	vec3 adjusted_target_location = target_location + target_positional_difference;
	current_camera_position = mix(current_camera_position, adjusted_target_location, time_step * 10.0);
	camera.SetPos(current_camera_position);
}

void SmoothCameraLookAt(vec3 target_location){
	float camera_distance = distance(target_location, current_camera_position);
	vec3 current_look_location = current_camera_position + (camera.GetFacing() * camera_distance);
	/* DebugDrawWireSphere(current_look_location, 0.5, vec3(1.0), _delete_on_update); */
	camera.LookAt(mix(current_look_location, target_location, time_step * 10.0));
}

void MessageWaitingForFadeOut(){
	for(uint i = 0; i < waiting_hotspot_ids.size(); i++){
		Object@ hotspot_obj = ReadObjectFromID(waiting_hotspot_ids[i]);
		hotspot_obj.ReceiveScriptMessage("drika_dialogue_fade_out_done");
	}
	waiting_hotspot_ids.resize(0);
}

bool HasFocus(){
	return (showing_choice && !EditorModeActive())?true:false;
}

bool DialogueCameraControl() {
	if((animating_camera || has_camera_control) && !EditorModeActive()){
		return true;
	}else{
		return false;
	}
}

void PlayLineContinueSound(int test_voice = -1) {
	if(!use_voice_sounds){return;}
    switch(test_voice == -1?current_actor_settings.voice:test_voice){
        case 0: PlaySoundGroup("Data/Sounds/concrete_foley/fs_light_concrete_edgecrawl.xml"); break;
        case 1: PlaySoundGroup("Data/Sounds/drygrass_foley/fs_light_drygrass_crouchwalk.xml"); break;
        case 2: PlaySoundGroup("Data/Sounds/cloth_foley/cloth_fabric_crouchwalk.xml"); break;
        case 3: PlaySoundGroup("Data/Sounds/dirtyrock_foley/fs_light_dirtyrock_crouchwalk.xml"); break;
        case 4: PlaySoundGroup("Data/Sounds/cloth_foley/cloth_leather_crouchwalk.xml"); break;
        case 5: PlaySoundGroup("Data/Sounds/grass_foley/fs_light_grass_run.xml", 0.5); break;
        case 6: PlaySoundGroup("Data/Sounds/gravel_foley/fs_light_gravel_crouchwalk.xml"); break;
        case 7: PlaySoundGroup("Data/Sounds/sand_foley/fs_light_sand_crouchwalk.xml", 0.7); break;
        case 8: PlaySoundGroup("Data/Sounds/snow_foley/fs_light_snow_run.xml", 0.5); break;
        case 9: PlaySoundGroup("Data/Sounds/wood_foley/fs_light_wood_crouchwalk.xml", 0.4); break;
        case 10: PlaySoundGroup("Data/Sounds/water_foley/mud_fs_walk.xml", 0.4); break;
        case 11: PlaySoundGroup("Data/Sounds/concrete_foley/fs_heavy_concrete_walk.xml", 0.5); break;
        case 12: PlaySoundGroup("Data/Sounds/drygrass_foley/fs_heavy_drygrass_walk.xml", 0.4); break;
        case 13: PlaySoundGroup("Data/Sounds/dirtyrock_foley/fs_heavy_dirtyrock_walk.xml", 0.5); break;
        case 14: PlaySoundGroup("Data/Sounds/grass_foley/fs_heavy_grass_walk.xml", 0.3); break;
        case 15: PlaySoundGroup("Data/Sounds/gravel_foley/fs_heavy_gravel_walk.xml", 0.3); break;
        case 16: PlaySoundGroup("Data/Sounds/sand_foley/fs_heavy_sand_run.xml", 0.3); break;
        case 17: PlaySoundGroup("Data/Sounds/snow_foley/fs_heavy_snow_crouchwalk.xml", 0.3); break;
        case 18: PlaySoundGroup("Data/Sounds/wood_foley/fs_heavy_wood_walk.xml", 0.3); break;
    }
}

void PlayLineStartSound(){
	if(!use_voice_sounds){return;}
	switch(current_actor_settings.voice){
		case 0: PlaySoundGroup("Data/Sounds/concrete_foley/fs_light_concrete_run.xml"); break;
		case 1: PlaySoundGroup("Data/Sounds/drygrass_foley/fs_light_drygrass_walk.xml"); break;
		case 2: PlaySoundGroup("Data/Sounds/cloth_foley/cloth_fabric_choke_move.xml"); break;
		case 3: PlaySoundGroup("Data/Sounds/dirtyrock_foley/fs_light_dirtyrock_run.xml"); break;
		case 4: PlaySoundGroup("Data/Sounds/cloth_foley/cloth_leather_choke_move.xml"); break;
		case 5: PlaySoundGroup("Data/Sounds/grass_foley/bf_grass_medium.xml", 0.5); break;
		case 6: PlaySoundGroup("Data/Sounds/gravel_foley/fs_light_gravel_run.xml"); break;
		case 7: PlaySoundGroup("Data/Sounds/sand_foley/fs_light_sand_run.xml", 0.7); break;
		case 8: PlaySoundGroup("Data/Sounds/snow_foley/bf_snow_light.xml", 0.5); break;
		case 9: PlaySoundGroup("Data/Sounds/wood_foley/fs_light_wood_run.xml", 0.4); break;
		case 10: PlaySoundGroup("Data/Sounds/water_foley/mud_fs_run.xml", 0.4); break;
		case 11: PlaySoundGroup("Data/Sounds/concrete_foley/fs_heavy_concrete_run.xml", 0.5); break;
		case 12: PlaySoundGroup("Data/Sounds/drygrass_foley/fs_heavy_drygrass_run.xml", 0.4); break;
		case 13: PlaySoundGroup("Data/Sounds/dirtyrock_foley/fs_heavy_dirtyrock_run.xml", 0.5); break;
		case 14: PlaySoundGroup("Data/Sounds/grass_foley/fs_heavy_grass_run.xml", 0.3); break;
		case 15: PlaySoundGroup("Data/Sounds/gravel_foley/fs_heavy_gravel_run.xml", 0.3); break;
		case 16: PlaySoundGroup("Data/Sounds/sand_foley/fs_heavy_sand_jump.xml", 0.3); break;
		case 17: PlaySoundGroup("Data/Sounds/snow_foley/fs_heavy_snow_jump.xml", 0.3); break;
		case 18: PlaySoundGroup("Data/Sounds/wood_foley/fs_heavy_wood_run.xml", 0.3); break;
	}
}
