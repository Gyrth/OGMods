#include "save/general.as"
#include "menu_common.as"
#include "music_load.as"
#include "train_track_save_load.as"

MusicLoad ml("Data/Music/menu.xml");

IMGUI@ imGUI;

// Coloring options
vec4 background_color(0.2f, 0.2f, 0.2f, 0.8f);
vec4 titlebar_color(0.4f, 0.4f, 0.4f, 1.0f);
vec4 item_background(0.4f, 0.4f, 0.4f, 1.0f);
vec4 item_hovered(0.3f, 0.3f, 0.3f, 1.0f);
vec4 item_clicked(0.3f, 0.3f, 0.3f, 1.0f);
vec4 text_color(0.9f, 0.9f, 0.9f, 1.0f);
vec4 black_color(0.0f, 0.0f, 0.0f, 1.0f);
int padding = 10;
bool open = true;

array<string> train_level_names = {	"Desert Outpost Train Track",
									"Forgotten Plains Train Track",
									"Patchy Highlands Train Track",
									"Red Desert Train Track",
									"Red Shards Train Track",
									"Scrubby Hills Train Track"};

array<string> train_levels = {	"desert_outpost_train_track.xml",
								"forgotten_plains_train_track.xml",
								"patchy_highlands_train_track.xml",
								"red_desert_train_track.xml",
								"red_shards_train_track.xml",
								"scrubby_hills_train_track.xml"};

int image_flags = TextureLoadFlags_NoMipmap | TextureLoadFlags_NoConvert |TextureLoadFlags_NoReduce;
array<TextureAssetRef> train_level_images = {	LoadTexture("Data/Images/desert_outpost_train_track.jpg", image_flags),
												LoadTexture("Data/Images/forgotten_plains_train_track.jpg", image_flags),
												LoadTexture("Data/Images/patchy_highlands_train_track.jpg", image_flags),
												LoadTexture("Data/Images/red_desert_train_track.jpg", image_flags),
												LoadTexture("Data/Images/red_shards_train_track.jpg", image_flags),
												LoadTexture("Data/Images/scrubby_hills_train_track.jpg", image_flags)};

int chosen_level_index = 0;
int num_intersections = 50;
int max_connections = 3;
float env_objects_mult = 1.0f;
int num_barrels = 10;

bool HasFocus() {
	return false;
}

void Initialize() {
	@imGUI = CreateIMGUI();
	// Start playing some music
	PlaySong("overgrowth_main");

	// We're going to want a 100 'gui space' pixel header/footer
	imGUI.setHeaderHeight(200);
	imGUI.setFooterHeight(200);

	imGUI.setFooterPanels(200.0f, 1400.0f);
	// Actually setup the GUI -- must do this before we do anything
	imGUI.setup();
	BuildUI();
	setBackGround();
	AddVerticalBar();
	LoadData();
}

void BuildUI(){
	IMDivider mainDiv( "mainDiv", DOHorizontal );
	IMDivider header_divider( "header_div", DOHorizontal );
	header_divider.setAlignment(CACenter, CACenter);
	AddTitleHeader("Train Track Editor", header_divider);
	imGUI.getHeader().setElement(header_divider);

	// Add it to the main panel of the GUI
	imGUI.getMain().setElement( @mainDiv );

	float button_trailing_space = 100.0f;
	float button_width = 400.0f;
	bool animated = true;

	IMDivider right_panel("right_panel", DOHorizontal);
	right_panel.setBorderColor(vec4(0,1,0,1));
	right_panel.setAlignment(CALeft, CABottom);
	right_panel.append(IMSpacer(DOHorizontal, button_trailing_space));
	AddButton("Back", right_panel, arrow_icon, button_back, animated, button_width);

	imGUI.getFooter().setAlignment(CALeft, CACenter);
	imGUI.getFooter().setElement(right_panel);
}

void Dispose() {
	imGUI.clear();
}

bool CanGoBack() {
	return true;
}

void Update() {
	UpdateKeyboardMouse();
	// process any messages produced from the update
	while( imGUI.getMessageQueueSize() > 0 ) {
		IMMessage@ message = imGUI.getNextMessage();

		if( message.name == "run_file" ){

		}else if( message.name == "Back" ){
			SaveData();
			this_ui.SendCallback( "back" );
		}
	}

	// Do the general GUI updating
	imGUI.update();
	UpdateController();
}

void Resize() {
	imGUI.doScreenResize(); // This must be called first
	setBackGround();
	AddVerticalBar();
}

void ScriptReloaded() {
	// Clear the old GUI
	imGUI.clear();
	// Rebuild it
	Initialize();
}

void DrawGUI() {
	imGUI.render();

	ImGui_PushStyleColor(ImGuiCol_WindowBg, background_color);
	ImGui_PushStyleColor(ImGuiCol_PopupBg, background_color);
	ImGui_PushStyleColor(ImGuiCol_TitleBgActive, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_TitleBgCollapsed, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_TitleBg, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_MenuBarBg, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_Text, text_color);
	ImGui_PushStyleColor(ImGuiCol_Header, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_HeaderHovered, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_HeaderActive, item_clicked);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarBg, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarGrab, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabHovered, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_ScrollbarGrabActive, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_CloseButton, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_Button, titlebar_color);
	ImGui_PushStyleColor(ImGuiCol_ButtonHovered, item_hovered);
	ImGui_PushStyleColor(ImGuiCol_ButtonActive, item_clicked);

	ImGui_Begin("Train Editor", open, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize);
	float target_height = screenMetrics.getScreenHeight() * 0.33f;
	float target_width = screenMetrics.getScreenWidth() * 0.50f;
	ImGui_SetWindowPos(vec2((screenMetrics.getScreenWidth() / 2.0f) - (target_width / 2.0f), (screenMetrics.getScreenHeight() / 2.0f) - (target_height / 2.0f)));
	ImGui_SetWindowSize(vec2(target_width, target_height));

	ImGui_PushStyleColor(ImGuiCol_FrameBg, vec4(0.0f));
	if(ImGui_BeginChildFrame(55, vec2(ImGui_GetWindowWidth()  - (padding * 3.0), ImGui_GetWindowHeight() - (padding * 3.0)))){
		ImGui_PushStyleColor(ImGuiCol_FrameBg, item_hovered);

		float option_name_width = 240.0;

		ImGui_Columns(2, false);
		ImGui_SetColumnWidth(0, option_name_width);

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Train Level");
		ImGui_NextColumn();
		float second_column_width = ImGui_GetContentRegionAvailWidth();
		ImGui_PushItemWidth(second_column_width);

		if(ImGui_BeginCombo("##Train Level ", train_level_names[chosen_level_index], ImGuiComboFlags_HeightLarge)){
			for(uint i = 0; i < train_levels.size(); i++){
				ImGui_Image(train_level_images[i], vec2(150.0f));
				ImGui_SameLine();
				if(ImGui_Selectable(train_level_names[i], int(i) == chosen_level_index, 0, vec2(0.0f, 150.0f))){
					chosen_level_index = i;
				}
			}
			ImGui_EndCombo();
		}
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Number of intersections");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		ImGui_SliderInt("##Number of intersections", num_intersections, 2, 100);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Environmental Objects Multiplier");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		ImGui_SliderFloat("##Environmental Objects Mult", env_objects_mult, 0.1f, 2.0f, "%.1f");
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Max Connections Per Intersection");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		ImGui_SliderInt("##Max Connections Per Intersection", max_connections, 2, 5);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_AlignTextToFramePadding();
		ImGui_Text("Number of Barrels");
		ImGui_NextColumn();
		ImGui_PushItemWidth(second_column_width);
		ImGui_SliderInt("##Number of Barrels", num_barrels, 1, 20);
		ImGui_PopItemWidth();
		ImGui_NextColumn();

		ImGui_NextColumn();
		if(ImGui_Button("Load Level")){
			SaveData();
			LoadLevel(train_levels[chosen_level_index]);
		}
		ImGui_SameLine();
		if(ImGui_Button("Reset to Defaults")){
			DeleteData();
			this_ui.SendCallback("back");
			this_ui.SendCallback("Data/Scripts/train_track_editor.as");
		}
		ImGui_EndChildFrame();
	}
	ImGui_End();
	ImGui_PopStyleColor(20);
}

void Draw() {

}

void Init(string str) {

}
