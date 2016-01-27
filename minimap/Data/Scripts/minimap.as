class Minimap {
    int gui_id;
    string minimapPath;
    float minimapHeight;
    float minimapWidth;
    int _movement_object = 21;
    int playerID = -1;

    int minimapSize = 20; //The minimap size in % from 0 to 100
    int iconSizePerc = 10; //The size of character icons
    int mapMaxX = 460; //The max X position on the level
    int mapMaxY = 460; //The max Y value on the level 
                        //X is actually Z on the map and Y is actually Z on the map.
    float backgroundOversize = 0.2f; //How much the background image (decor) should overflow the original minimap.
    float origIconSize;
    float iconSize;
    float iconScale;
    string backgroundPath = "Data/UI/spawner/thumbs/Decal/thick_tan_rug.png";
    string charIconPath = "Data/UI/spawner/thumbs/Decal/icon_rabbit.png";

    void Init(string levelName){
        gui_id = -1;
        //The minimap image does not change so get the info after the level loads.
        HUDImage @minimapImage = hud.AddImage();
        minimapPath = "Data/Textures/ui/Minimaps/" + levelName + ".tga";
        minimapImage.SetImageFromPath(minimapPath);
        minimapWidth = minimapImage.GetWidth();
        minimapHeight = minimapImage.GetHeight();

        //The icons won't change as well. So get the size and scale just once.
        HUDImage @charIconImage = hud.AddImage();
        charIconImage.SetImageFromPath(charIconPath);
        origIconSize = charIconImage.GetWidth();
        iconSize = iconSizePerc*GetScreenWidth()/100;
        iconScale = iconSize/minimapWidth;
    }

    int GetPlayerCharacterID() {
        int num = GetNumCharacters();
        for(int i=0; i<num; ++i){
            MovementObject@ char = ReadCharacter(i);
            if(char.controlled){
                return i;
            }
        }
        return -1;
    }

    Minimap() {
        
    }
    
    void Update(){
        
    }
    
    void MoveGUI(int gui_id){
        if(gui_id != -1){
            gui.MoveTo(gui_id,GetScreenWidth()/2-400,GetScreenHeight()/2-300);
        }    
    } 
    
    void DrawGUI(){
        
        HUDImage @image = hud.AddImage();
        image.SetImageFromPath(minimapPath);
        float newWidth = minimapSize*GetScreenWidth()/100;
        
        float newScale = newWidth/minimapWidth;
        image.scale = vec3(newScale);

        //These X and Y values will determine the actual startingpoint of all the minimap elements.
        float startingPointX = 30.0f;
        float startingPointY = GetScreenHeight() - (minimapHeight * newScale) - 30.0f;
        
        image.position.x = startingPointX;
        image.position.y = startingPointY;
        image.position.z = 2;

        float minimMiddleX = startingPointX + ((minimapWidth * newScale) / 2);
        float minimMiddleY = startingPointY + ((minimapHeight * newScale) / 2);

        //Adding a background to the minimap

        HUDImage @backgroundImage = hud.AddImage();
        backgroundImage.SetImageFromPath(backgroundPath);
        
        float backgroundWidth = backgroundImage.GetWidth();
        
        float newBackgroundSize = newWidth * (1.0f + backgroundOversize);
        float newBackgroundScale = (newBackgroundSize / backgroundWidth);
        backgroundImage.scale = vec3(newBackgroundScale);

        backgroundImage.position.x = startingPointX - (newWidth * backgroundOversize / 2);
        backgroundImage.position.y = startingPointY - (newWidth * backgroundOversize / 2);
        //The background is on a lower Z value to make it appear behind the other elements.
        backgroundImage.position.z = 1;

        //Adding the actual character icons to the minimap
        playerID = GetPlayerCharacterID();
        array<int> ids = GetObjectIDsType(_movement_object);
        for(uint i = 0; i < ids.size(); i++){
            MovementObject @char = ReadCharacterID(ids[i]);

            HUDImage @charIcon = hud.AddImage();
            charIcon.SetImageFromPath(charIconPath);
            charIcon.scale = vec3(iconScale);
            charIcon.position.x = (minimMiddleX + ((newWidth / 2) * char.position.z / mapMaxX) - ((origIconSize * iconScale) / 2));
            charIcon.position.y = (minimMiddleY + (((newWidth / 2) * char.position.x) / mapMaxY) - ((origIconSize * iconScale) / 2));
            charIcon.position.z = 2;
            vec4 iconColor;
            
            //If there is no character currently controlled the icons will all have the same color (white).
            if(playerID != -1){
                MovementObject@ player = ReadCharacter(playerID);
                if(char.controlled){
                    //If the character is controlled it will be blue.
                    iconColor = vec4(0.3,0.3,1.0,1.0);
                }else if(char.OnSameTeam(player)){
                    //If it's not controlled but friendly, green.
                    iconColor = vec4(0.3,1.0,0.3,1.0);
                }else{
                    //and red for enemies.
                    iconColor = vec4(1.0,0.3,0.3,1.0);
                }
                charIcon.color = iconColor;
            }
        }
    }
}