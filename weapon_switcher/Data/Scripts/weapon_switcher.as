IMGUI@ imGUI;
array<Weapon@> weapons;
string toggle_key = "r";
bool has_ui = false;
int nr_shown_weapons = 5;
int current_weapon = 0;
int whole_width = 2560;
bool fade_in = true;
int fade_in_time = 150;
int slide_amount = 50;
bool direction = true;
int weapon_id = -1;
float switcher_time = 0.0f;
vec4 background_color = vec4(0.15f,0.15f,0.15f,0.75f);
string square = "Textures/ui/menus/main/white_square.png";
string empty = "UI/spawner/thumbs/Hotspot/empty.png";
FontSetup main_font("arial", 45, HexColor("#CCCCCC"), true);

class Weapon{
    string name;
    string item_path;
    string thumb_path;
    Weapon(string _name, string _item_path, string _thumb_path){
        name = _name;
        item_path = _item_path;
        thumb_path = _thumb_path;
    }
}

void Init(string p_level_name) {
    @imGUI = CreateIMGUI();
	weapons.insertLast(Weapon("Empty",             		"empty",                                				empty));
    weapons.insertLast(Weapon("Cat Rapier",             "Data/Items/Rapier.xml",                                "UI/spawner/thumbs/Interactive Objects/Cat Rapier.png"));
    weapons.insertLast(Weapon("Cat Gauche",             "Data/Items/MainGauche.xml",                            "UI/spawner/thumbs/Interactive Objects/Main Gauche.png"));
    weapons.insertLast(Weapon("Dog Broad Sword",        "Data/Items/DogWeapons/DogBroadSword.xml",              "UI/spawner/thumbs/Interactive Objects/Dog Broad Sword.png"));
    weapons.insertLast(Weapon("Dog Sword",              "Data/Items/DogWeapons/DogSword.xml",                   "UI/spawner/thumbs/Interactive Objects/Dog Sword.png"));
    weapons.insertLast(Weapon("Dog Knife",              "Data/Items/DogWeapons/DogKnife.xml",                   "UI/spawner/thumbs/Interactive Objects/Dog Knife.png"));
    weapons.insertLast(Weapon("Dog Spear",              "Data/Items/DogWeapons/DogSpear.xml",                   "UI/spawner/thumbs/Interactive Objects/Dog Spear.png"));
    weapons.insertLast(Weapon("Dog Hammer",             "Data/Items/DogWeapons/DogHammer.xml",                  "UI/spawner/thumbs/Interactive Objects/Dog Hammer.png"));
    weapons.insertLast(Weapon("Dog Glaive",             "Data/Items/DogWeapons/DogGlaive.xml",                  "UI/spawner/thumbs/Interactive Objects/Dog Glaive.png"));
    weapons.insertLast(Weapon("Rabbit Catcher",         "Data/Items/DogWeapons/RabbitCatcher.xml",              "UI/spawner/thumbs/Interactive Objects/Rabbit Catcher.png"));

    weapons.insertLast(Weapon("Rabbit Knife",           "Data/Items/rabbit_weapons/rabbit_knife.xml",           "UI/spawner/thumbs/Interactive Objects/rabbit_knife.png"));
    weapons.insertLast(Weapon("Rabbit Throwing Knife",  "Data/Items/rabbit_weapons/rabbit_throwing_knife.xml",  "UI/spawner/thumbs/Interactive Objects/rabbit_throwing_knife.png"));
    weapons.insertLast(Weapon("Macuahuitl Metal",       "Data/Items/macuahuitl_metal.xml",                      "UI/spawner/thumbs/Interactive Objects/Macahuitl Metal.png"));
    weapons.insertLast(Weapon("Macuahuitl Glass",       "Data/Items/macuahuitl_glass.xml",                      "UI/spawner/thumbs/Interactive Objects/Macahuitl Glass.png"));
    weapons.insertLast(Weapon("Staff",                  "Data/Items/staffbasic.xml",                            "UI/spawner/thumbs/Interactive Objects/staffbasic.png"));

    weapons.insertLast(Weapon("Rat Machete",            "Data/Items/rat_weapons/rat_machete.xml",               "UI/spawner/thumbs/Interactive Objects/rat_machete.png"));
    weapons.insertLast(Weapon("Rat Throwing Blade",     "Data/Items/rat_weapons/rat_throwing_blade.xml",        "UI/spawner/thumbs/Interactive Objects/rat_throwing_blade.png"));

    weapons.insertLast(Weapon("Bastard Sword",          "Data/Items/Bastard.xml",                               "UI/spawner/thumbs/Interactive Objects/bastard Sword.png"));
    weapons.insertLast(Weapon("Flint Knife",            "Data/Items/flint_knife.xml",                           "UI/spawner/thumbs/Interactive Objects/flint_knife.png"));
    weapons.insertLast(Weapon("Flint Knife C Two",      "Data/Items/flint_knife_c2.xml",                        "UI/spawner/thumbs/Interactive Objects/flint_knife_c2.png"));
    weapons.insertLast(Weapon("Gabe Knife",             "Data/Items/gabenife.xml",                              "UI/spawner/thumbs/Interactive Objects/gabenife.png"));
}

void DrawGUI() {
	imGUI.render();
}

void AddUI(){
    imGUI.setup();
    IMDivider main( "main", DOHorizontal );
	imGUI.getMain().setAlignment(CACenter, CACenter);

    float size = whole_width / nr_shown_weapons;
    int start_at = current_weapon - (nr_shown_weapons / 2);
    int end_at = start_at + nr_shown_weapons;
    for(int i = start_at; i < end_at; i++){
        if(i < 0 || i > int(weapons.size() - 1)){
            AddSingleWeaponUI(main, size, empty, "", 0.0f, 0.0f);
            continue;
        }
        string thumb_path = weapons[i].thumb_path;
        string name = weapons[i].name;
        float size_offset = (abs(current_weapon - i) * 100.0f);
        float opacity = 1.0f - (abs(current_weapon - i) * 0.35f);
        AddSingleWeaponUI(main, size, thumb_path, name, opacity, size_offset);
    }

	imGUI.getMain().setElement(main);
}

void AddSingleWeaponUI(IMDivider@ parent, float size, string thumb_path, string name, float opacity, float size_offset){
    float thumb_size_offset = 150.0f;
    float background_size_offset = 25.0f;

    IMContainer weapon_container(size, size);
    parent.append(weapon_container);
    IMDivider weapon_divider("weapon_divider", DOVertical);
    weapon_container.setElement(weapon_divider);

    FontSetup title_font = main_font;
    title_font.color.a *= opacity;
    title_font.size = int(title_font.size * opacity);
    IMText title(name, title_font);
    weapon_divider.append(title);

    IMImage background(square);
    background.setZOrdering(-1);
    vec4 color = background_color;
    color.a *= opacity;
    background.setColor(color);

    background.scaleToSizeX(size - background_size_offset - size_offset);
    weapon_container.addFloatingElement(background, "background", vec2((background_size_offset + size_offset) / 2.0f));

    IMImage thumb(thumb_path);
    vec4 thumb_color = vec4(1.0f);
    thumb_color.a *= opacity;
    thumb.setColor(thumb_color);
    thumb.scaleToSizeX(max(10.0f, size - thumb_size_offset - size_offset));
    weapon_divider.append(thumb);

    if(fade_in){
        background.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
        thumb.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
        title.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
    }else if(direction){
        weapon_container.addUpdateBehavior(IMMoveIn ( 150.0f, vec2(size, 0), outExpoTween ), "");
    }else{
        weapon_container.addUpdateBehavior(IMMoveIn ( 150.0f, vec2(size * -1, 0), outExpoTween ), "");
    }
}

void RemoveUI(){
	imGUI.clear();
}

void RefreshUI(){
	RemoveUI();
	AddUI();
}

void SetWindowDimensions(int w, int h)
{
	imGUI.doScreenResize();
}

void Update(int paused) {
    if(has_ui){
        int new_weapon = current_weapon;
        if(GetInputDown(0, "mousescrolldown") && !EditorModeActive()){
            switcher_time = the_time;
            direction = true;
    		new_weapon = min(current_weapon+1, weapons.size() -1);
    	} else if(GetInputDown(0, "mousescrollup") && !EditorModeActive()){
            switcher_time = the_time;
            direction = false;
            new_weapon = max(0, current_weapon-1);
    	}
        if(new_weapon != current_weapon){
            current_weapon = new_weapon;
            RefreshUI();
            SwitchToWeapon();
        }
        if(the_time - switcher_time > 2.0f){
            RemoveUI();
            fade_in = true;
            has_ui = false;
        }
    }else if(!EditorModeActive()){
        if(GetInputDown(0, "mousescrollup") || GetInputDown(0, "mousescrolldown")){
            switcher_time = the_time;
            AddUI();
            fade_in = false;
            has_ui = true;
        }
    }
    imGUI.update();
}

void SwitchToWeapon(){
    int player_id = GetPlayerCharacterID();
    if(player_id == -1){
        return;
    }
    if(ObjectExists(weapon_id)){
        DeleteObjectID(weapon_id);
    }
    Object@ player = ReadObjectFromID(player_id);
    MovementObject@ player_mo = ReadCharacterID(player_id);
    if(player_mo.GetIntVar("knocked_out") != _awake){
        return;
    }
    player_mo.Execute("DropWeapon();");
	if(weapons[current_weapon].item_path != "empty"){
    	weapon_id = CreateObject(weapons[current_weapon].item_path);
    	Object@ weapon_obj = ReadObjectFromID(weapon_id);
		weapon_obj.SetTranslation(vec3(0.0f, -10000.0f, 0.0f));
		player.AttachItem(weapon_obj, _at_grip, false);
	}
}

int GetPlayerCharacterID() {
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            return char.GetID();
        }
    }
    return -1;
}
