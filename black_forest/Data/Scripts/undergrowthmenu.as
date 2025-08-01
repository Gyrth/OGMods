#include "ui_effects_undergrowth.as"
#include "ui_tools.as"
#include "music_load.as"

AHGUI::FontSetup labelFont("go3v2", 70,HexColor("#fff"));
AHGUI::FontSetup versionFont("go3v2", 65, HexColor("#fff"));

int title_spacing = 100;
int menu_item_spacing = 20;

MusicLoad ml("Data/Music/undergrowth.xml");

AHGUI::MouseOverPulseColor buttonHover(
                                        HexColor("#ff4516"),
                                        HexColor("#ff8216"), 2 );

bool draw_settings = false;

class MainMenuGUI : AHGUI::GUI {
    RibbonBackground ribbon_background;

    MainMenuGUI()
    {
        //restrict16x9(false);

        super();

        ribbon_background.Init();

        Init();
    }

    void Init()
    {
        AHGUI::Divider@ mainpane = root.addDivider( DDTop,
                                                    DOVertical,
                                                    ivec2( UNDEFINEDSIZEI, 1140 ) );

        /*
        AHGUI::Image alphasticker = AHGUI::Image("Textures/ui/main_menu/alphasticker.png");
        alphasticker.scaleToSizeX( 350 );
        mainpane.addFloatingElement( alphasticker, "alphasticker", ivec2( 2100, 100 ));
        */

        /* 
        // TODO: Why is this making it crash on MAC?? -David
        AHGUI::Text alphaversion = AHGUI::Text( GetBuildVersionShort().split("-")[0], versionFont );
        mainpane.addFloatingElement( alphaversion, "alphaversion", ivec2( 1800, 300 ));
        */

        AHGUI::Image titleImage = AHGUI::Image("UI/logo2.png");
        mainpane.addElement(titleImage,DDTop);

        mainpane.addSpacer(title_spacing,DDTop);
/*
        {
            AHGUI::Text buttonText = AHGUI::Text("BEGIN", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("begin") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }
*/
        {
            AHGUI::Text buttonText = AHGUI::Text("Play", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("letsgo") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }

        {
            AHGUI::Text buttonText = AHGUI::Text("Credits", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("credits") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }

        {
            AHGUI::Text buttonText = AHGUI::Text("Back", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("exit") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }
    }

    void processMessage( AHGUI::Message@ message )
    {
        Log( info, "Got processMessage " + message.name );
        if( message.name == "letsgo" )
        {
            this_ui.SendCallback("undergrowth_redux.xml");
        }
        else if( message.name == "credits" )
        {
            this_ui.SendCallback( "undergrowthCredits.as" );
        }
        else if( message.name == "mods" )
        {
            this_ui.SendCallback( "mods" );
        }
        else if( message.name == "exit" )
        {
            this_ui.SendCallback( "exit" );
        }
        else if( message.name == "settings" )
        {
            this_ui.SendCallback( "main_menu_settings.as" );
        }
    }

    void update()
    {
        //Other things here, before

        AHGUI::GUI::update();
    }
    
string GetRandomBackground(){
    array<string> background_paths;
    int counter = 0;
        string path = "Data/UI/darkbg.jpg";
    if(background_paths.size() < 1){
        return "Textures/error.tga";
    }else{
        return background_paths[rand()%background_paths.size()];
    }
}


    void render() {
        EnterTelemetryZone("MainMenuGUI::render()");

        EnterTelemetryZone("ribbon_background.Update()");
        ribbon_background.Update();
        LeaveTelemetryZone();

        EnterTelemetryZone("ribbon_background.DrawGUI");
        ribbon_background.DrawGUI(1.1f);
        LeaveTelemetryZone();

        EnterTelemetryZone("hud.Draw()");
        hud.Draw();
        LeaveTelemetryZone();

        EnterTelemetryZone("AHGUI::GUI::render()");
        AHGUI::GUI::render();
        LeaveTelemetryZone();

        LeaveTelemetryZone();

        if(draw_settings){
            ImGui_Begin("Settings", draw_settings);
            ImGui_DrawSettings();
            ImGui_End();
        }
    }

}


MainMenuGUI@ mainmenuGUI = @MainMenuGUI();


bool HasFocus() {
    return false;
}

void Initialize() {
    PlaySong("sad0");
}

void Dispose() {
}

bool CanGoBack() {
    return true;
}

void Update() {

    mainmenuGUI.update();
}

void DrawGUI() {
    EnterTelemetryZone("DrawGUI");
    mainmenuGUI.render();
    LeaveTelemetryZone();
}

void Draw() {
}

void Init(string str) {
}

void StartMainMenu() {

}

void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "reset"){
        
    }else if(token == "Back"){

    }
}
