#include "menu_common.as"
//#include "arena_meta_persistence.as"
#include "music_load.as"

// Load the music 
MusicLoad ml("Data/Music/undergrowth.xml");

// Constants because I'm not typing this in again
const float postHeader = 40;
const float postName = 20;
const float postGroup = 80;
const float scrollUpdateSize = 0.5;

// Just to avoid some repeated text
// Some structure to hold the credits in 
IMDivider creditDiv( "mainDiv", DOVertical );

void addToTextScroll( string text, bool isHeaer = false ) {
	if( isHeaer ) {
		// New text object
		IMText newText( text, creditFontBig );
		
		// Add it to the divider
		creditDiv.append( newText );

		// Add some space
		creditDiv.appendSpacer( postHeader );
	}
	else {
		// Second verse, same as the first
		IMText newText( text, creditFontSmall );	
		creditDiv.append( newText );	
		creditDiv.appendSpacer( postName );
	}
	
}

// The actual GUI object 
IMGUI@ imGUI;

void Initialize() {
    @imGUI = CreateIMGUI();
	// Kick off some music
	PlaySong("credits");

	// Actually setup the GUI -- must do this before we do anything 
    imGUI.setup();

    // The center will hold in this case
    creditDiv.setAlignment( CACenter, CACenter );

    // The following is really showing my PhD in CS to it's maximum advantage
	addToTextScroll( "The Undergrowth:", true );
	

	creditDiv.append( IMImage( "Images/foobar.png" ) );
	creditDiv.appendSpacer( postGroup );
	creditDiv.appendSpacer( postGroup );

	addToTextScroll( "Programming", true );
	addToTextScroll( "Level Design", true );
	addToTextScroll( "Sound Design", true );
	addToTextScroll( "Concept", true );
	addToTextScroll( "urb (Lord Frigidaire)" );
	
	creditDiv.appendSpacer( postGroup );

	addToTextScroll( "Assets", true);
	addToTextScroll( "Black Forest By Gyrth McMulin");
	addToTextScroll( "DeathClaw By Akazi");
	addToTextScroll( "Jim's Weapon Pack by TwoWolves");
	addToTextScroll( "Fixed Weapon Pack by Enix");
	addToTextScroll( "Old China assets by Markuss (ported by Edo)");
	addToTextScroll( "Leg Cannon Damage mod by Neetch");
	addToTextScroll( "House model by Halzoid");
	//0% 
	
	creditDiv.appendSpacer( postGroup );

	addToTextScroll( "Programming Help", true);
	addToTextScroll( "Gyrth McMulin");
	addToTextScroll( "Merlyn (Kavika)");
	addToTextScroll( "Keril Artemov");
	addToTextScroll( "MNG (never heard of her)");

	creditDiv.appendSpacer( postGroup );
	
	addToTextScroll( "Music", true);
	addToTextScroll( "Game music taken from Total War Shogun 1 and 2");
	addToTextScroll( "Permadeath music from Battlefield 4");
	addToTextScroll( "Credit music, Masaaki Hirao");

	creditDiv.appendSpacer( postGroup );
	
	addToTextScroll( "Additional sounds taken from:", true);
	addToTextScroll( "Shogun Total War 1");
	addToTextScroll( "Shogun Total War 2");
	addToTextScroll( "Battlefield 1");
	addToTextScroll( "Battlefield 4");
	addToTextScroll( "Torchlight");
	addToTextScroll( "Anarchy Online");

creditDiv.appendSpacer( postGroup );

	addToTextScroll( "Images:", true);
	addToTextScroll( "Loading screens from King of Fighters (SNK)");
	addToTextScroll( "Main screen, Stan Sakai");
	addToTextScroll( "Inventory panel bunny by Solitarium");
	addToTextScroll( "Icons by 7Soul1");

	creditDiv.appendSpacer( postGroup );
	
	addToTextScroll( "Redaction ", true);
	addToTextScroll( "Pepperthumb");

	creditDiv.appendSpacer( postGroup );
	
	addToTextScroll( "Special thanks to", true);
	addToTextScroll( "mudandblood.net community");
	addToTextScroll( "Wolfire discord community");

	creditDiv.appendSpacer( postGroup );

	creditDiv.append( IMImage( "Images/foobar.png" ) );


	// Now make this a 'floating component' of the main container
	
	// Actually add it to the container
	// start at the bottom of the screen
	imGUI.getMain().addFloatingElement(	creditDiv, 	
									    "credits", 
									    vec2(
											UNDEFINEDSIZE, // Will center 
											screenMetrics.GUISpace.y
										)
									  );

	// Send a message if somebody clicks anywhere
	imGUI.getMain().addLeftMouseClickBehavior( IMFixedMessageOnClick("click"), "click" );

}

void Update(){

	bool done = false;

	// Check to see if we get an early exit 
	if(GetInputPressed(0,'esc')){
    	done = true;
    }

    // process waiting messages
    while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();
        if( message.name == "click" )
        {
        	done = true;
        }
    }

    // Move the credits up
    // Get the position 
    vec2 creditPos = imGUI.getMain().getElementPosition("credits");

    //Check to see if we're off the screen
    if( creditPos.y + creditDiv.getSizeY() < 0.0 ) {
    	done = true;
    }

    creditPos.y -= scrollUpdateSize;

    imGUI.getMain().moveElement( "credits", creditPos );

    if( done ) {
    	this_ui.SendCallback("back");
    }

    imGUI.update();
}

void Resize() {
    imGUI.doScreenResize();
}

void DrawGUI(){
    imGUI.render();
}

void Draw(){
}

void Init(string str){
}

void StartArenaMeta(){

}
bool CanGoBack(){
	return true;
}
void Dispose(){

}
