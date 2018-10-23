#include "save/general.as"
#include "menu_common.as"
#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

const int item_per_screen = 4;
const int rows_per_screen = 3;

IMGUI@ imGUI;
array<LevelInfo@> comic_reader = {};

bool HasFocus() {
    return false;
}

void Initialize() {
    @imGUI = CreateIMGUI();
    // Start playing some music
    PlaySong("overgrowth_main");
    comic_reader.resize(0);

    // We're going to want a 100 'gui space' pixel header/footer
	imGUI.setHeaderHeight(200);
    imGUI.setFooterHeight(200);

	imGUI.setFooterPanels(200.0f, 1400.0f);
    // Actually setup the GUI -- must do this before we do anything
    imGUI.setup();
    CreateComicList();
    BuildUI();
	setBackGround();
	AddVerticalBar();
}

void CreateComicList() {
    array<ModID>@ active_sids = GetActiveModSids();
    for( uint i = 0; i < active_sids.length(); i++ ) {
        array<MenuItem>@ menu_items = ModGetMenuItems(active_sids[i]);
        for( uint k = 0; k < menu_items.length(); k++ ) {
            if( menu_items[k].GetCategory() == "comic" ) {
                string thumbnail_path = menu_items[k].GetThumbnail();
                if( thumbnail_path == "" ) {
                    thumbnail_path = "../" + ModGetThumbnail(active_sids[i]);
                }
				Log(info, menu_items[k].GetTitle());
				Log(info, menu_items[k].GetThumbnail());
				Log(info, menu_items[k].GetPath());
                LevelInfo li(menu_items[k].GetPath(), menu_items[k].GetTitle(), thumbnail_path, true, false);
				comic_reader.insertLast(li);
            }
        }
    }
}

void BuildUI(){
    IMDivider mainDiv( "mainDiv", DOHorizontal );
	IMDivider header_divider( "header_div", DOHorizontal );
	header_divider.setAlignment(CACenter, CACenter);
	AddTitleHeader("Comics", header_divider);
	imGUI.getHeader().setElement(header_divider);

    int initial_offset = 0;
    if( StorageHasInt32("comic_reader-shift_offset") ) {
        initial_offset = StorageGetInt32("comic_reader-shift_offset");
    }
    while( initial_offset >= int(comic_reader.length()) ) {
        initial_offset -= item_per_screen;
        if( initial_offset < 0 ) {
            initial_offset = 0;
            break;
        }
    }
	CreateMenu(mainDiv, comic_reader, "comic_reader", initial_offset, item_per_screen, rows_per_screen, false, false, menu_width, menu_height, false,false,false,true);
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
			Log(info, "index " + message.getInt(0));
			string comic_path = comic_reader[message.getInt(0)].file;
			Log(info, "Set comic path " + comic_path);
			SetInterlevelData("load_comic", comic_path);
            this_ui.SendCallback("Data/Scripts/comic_creator_inmenu.as");
        }
        else if( message.name == "Back" ){
            this_ui.SendCallback( "back" );
        }
		else if( message.name == "shift_menu" ){
            StorageSetInt32("comic_reader-shift_offset", ShiftMenu(message.getInt(0)));
            SetControllerItemBeforeShift();
            BuildUI();
            SetControllerItemAfterShift(message.getInt(0));
		}
        else if( message.name == "refresh_menu_by_name" ){
			string current_controller_item_name = GetCurrentControllerItemName();
			BuildUI();
			SetCurrentControllerItem(current_controller_item_name);
		}
		else if( message.name == "refresh_menu_by_id" ){
			int index = GetCurrentControllerItemIndex();
			BuildUI();
			SetCurrentControllerItem(index);
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
}

void Draw() {

}

void Init(string str) {

}
