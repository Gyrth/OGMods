IMGUI@ imGUI;
array<Character@> characters;
bool has_ui = false;
int nr_shown_characters = 3;
int current_character = -1;
int current_character_ui = -1;
int new_character = -1;
int whole_height = 1440;
bool fade_in = true;
int fade_in_time = 150;
int slide_amount = 50;
bool direction = true;
vec4 background_color = vec4(0.0f,0.0f,0.0f,0.15f);
string square = "Textures/ui/menus/main/white_square.png";
string empty = "UI/spawner/thumbs/Hotspot/empty.png";
FontSetup main_font("OptimusPrinceps", 45, HexColor("#CCCCCC"), true);

class Character{
    string name;
    string character_path;
    string thumb_path;
    Character(string _name, string _character_path, string _thumb_path){
        name = _name;
        character_path = _character_path;
        thumb_path = _thumb_path;
    }
}

void Init(string p_level_name) {
    @imGUI = CreateIMGUI();
	characters.insertLast(Character("Guard",						"Data/Characters/guard.xml",					"UI/spawner/thumbs/Character/base_guard_actor.png"));
	characters.insertLast(Character("Raider Rabbit",				"Data/Characters/raider_rabbit.xml",			"UI/spawner/thumbs/Character/raider_rabbit_actor.png"));
	characters.insertLast(Character("Pale Turner",					"Data/Characters/pale_turner.xml",				"UI/spawner/thumbs/Character/pale_turner_actor.png"));
	characters.insertLast(Character("Turner",						"Data/Characters/turner.xml",					"UI/spawner/thumbs/Object/default Turner.png"));
	characters.insertLast(Character("Male Rabbit 1",				"Data/Characters/male_rabbit_1.xml",			"UI/spawner/thumbs/Character/Male_rabbit_1_actor.png"));
	characters.insertLast(Character("Male Rabbit 2",				"Data/Characters/male_rabbit_2.xml",			"UI/spawner/thumbs/Character/Male_rabbit_2_actor.png"));
	characters.insertLast(Character("Male Rabbit 3",				"Data/Characters/male_rabbit_3.xml",			"UI/spawner/thumbs/Character/Male_rabbit_3_actor.png"));

	characters.insertLast(Character("Female Rabbit 1",				"Data/Characters/female_rabbit_1.xml",			"UI/spawner/thumbs/Character/female_rabbit_1_actor.png"));
	characters.insertLast(Character("Female Rabbit 2",				"Data/Characters/female_rabbit_2.xml",			"UI/spawner/thumbs/Character/female_rabbit_2_actor.png"));
	characters.insertLast(Character("Female Rabbit 3",				"Data/Characters/female_rabbit_3.xml",			"UI/spawner/thumbs/Character/female_rabbit_3_actor.png"));

	characters.insertLast(Character("Pale Rabbit Civ",				"Data/Characters/pale_rabbit_civ.xml",			"UI/spawner/thumbs/Character/pale_rabbit_civ_actor.png"));
	characters.insertLast(Character("Fancy Striped Cat",			"Data/Characters/fancy_striped_cat.xml",		"UI/spawner/thumbs/Character/fancy_striped_cat_actor.png"));
	characters.insertLast(Character("Female Cat",					"Data/Characters/female_cat.xml",				"UI/spawner/thumbs/Character/female_cat_actor.png"));
	characters.insertLast(Character("Male Cat",						"Data/Characters/male_cat.xml",					"UI/spawner/thumbs/Character/male_cat_actor.png"));
	characters.insertLast(Character("Striped Cat",					"Data/Characters/striped_cat.xml",				"UI/spawner/thumbs/Object/Striped Cat.png"));

	characters.insertLast(Character("Rat",							"Data/Characters/rat.xml",						"UI/spawner/thumbs/Character/rat_actor.png"));
	characters.insertLast(Character("Hooded Rat",					"Data/Characters/hooded_rat.xml",				"UI/spawner/thumbs/Character/Hooded_rat_actor.png"));
    characters.insertLast(Character("Female Rat",					"Data/Characters/female_rat.xml",				"UI/spawner/thumbs/Character/female_rat_actor.png"));

	characters.insertLast(Character("Wolf",							"Data/Characters/wolf.xml",						"UI/spawner/thumbs/Character/IGF_wolfActor.png"));
	characters.insertLast(Character("Male Wolf",					"Data/Characters/male_wolf.xml",				"UI/spawner/thumbs/Character/male_wolf_actor.png"));

	characters.insertLast(Character("Light Armored Dog Big",		"Data/Characters/lt_dog_big.xml",				"UI/spawner/thumbs/Character/light_armored_dog_male_3_actor.png"));
	characters.insertLast(Character("Light Armored Dog Female",		"Data/Characters/lt_dog_female.xml",			"UI/spawner/thumbs/Character/light_armored_dog_female_actor.png"));
	characters.insertLast(Character("Light Armored Dog Male 1",		"Data/Characters/lt_dog_male_1.xml",			"UI/spawner/thumbs/Character/light_armored_dog_male_1_actor.png"));
	characters.insertLast(Character("Light Armored Dog Male 2",		"Data/Characters/lt_dog_male_2.xml",			"UI/spawner/thumbs/Character/light_armored_dog_male_2_actor.png"));

	characters.insertLast(Character("Rabbot",						"Data/Characters/rabbot.xml",					"UI/spawner/thumbs/Object/Rabbot.png"));

	CheckCharacterPaths();
}

void GetCurrentCharacter(){
	int player_id = GetPlayerCharacterID();
    if(player_id == -1){
        return;
    }
    Object@ player = ReadObjectFromID(player_id);
    MovementObject@ player_mo = ReadCharacterID(player_id);
	for(uint i = 0; i < characters.size(); i++){
		Log(info, player_mo.char_path);
		if(player_mo.char_path == characters[i].character_path){
			current_character = i;
			current_character_ui = i;
			new_character = i;
			break;
		}
	}
}

void CheckCharacterPaths(){
	for(uint i = 0; i < characters.size(); i++){
		if(!FileExists(characters[i].character_path)){
			characters.removeAt(i);
			i--;
		}
	}
}

void DrawGUI() {
	imGUI.render();
}
void AddUI(){
    imGUI.setup();
    IMDivider main( "main", DOVertical );
	imGUI.getMain().setAlignment(CACenter, CATop);

    vec2 size = vec2(whole_height / nr_shown_characters + 400.0, whole_height / nr_shown_characters);
    int start_at = current_character_ui - (nr_shown_characters / 2);
    int end_at = start_at + nr_shown_characters;
    for(int i = start_at; i < end_at; i++){
        if(i < 0 || i > int(characters.size() - 1)){
            AddSingleCharacterUI(main, size, empty, "", 0.0f, 0.0f);
            continue;
        }
        string thumb_path = characters[i].thumb_path;
        string name = characters[i].name;
        float size_offset = (abs(current_character_ui - i) * 100.0f);
        float opacity = 1.0f - (abs(current_character_ui - i) * 0.35f);
        AddSingleCharacterUI(main, size, thumb_path, name, opacity, size_offset);
    }

	imGUI.getMain().setElement(main);
}

void AddSingleCharacterUI(IMDivider@ parent, vec2 size, string thumb_path, string name, float opacity, float size_offset){
    float thumb_size_offset = 100.0f;
    float background_size_offset = 0.0f;

    IMContainer character_container(size.x, size.y);
    parent.append(character_container);
    IMDivider character_divider("character_divider", DOVertical);
    character_container.setElement(character_divider);

    FontSetup title_font = main_font;
    title_font.color.a *= opacity;
    title_font.size = int(title_font.size * opacity);
    IMText title(name, title_font);
    character_divider.append(title);

    IMImage background(square);
	if(name != ""){
		background.showBorder();
		background.setBorderSize(5.0);
		background.setBorderColor(vec4(0, 0, 0, 1));
	}
    background.setZOrdering(-1);
    vec4 color = background_color;
    color.a *= opacity;
    background.setColor(color);

	background.setSize(vec2(size.x - background_size_offset - size_offset, size.y - background_size_offset - size_offset));
    character_container.addFloatingElement(background, "background", vec2((background_size_offset + size_offset) / 2.0f));

    IMImage thumb(thumb_path);
    vec4 thumb_color = vec4(1.0f);
    thumb_color.a *= opacity;
    thumb.setColor(thumb_color);
    thumb.scaleToSizeX(max(10.0f, size.y - thumb_size_offset - size_offset));
    character_divider.append(thumb);

    if(fade_in){
        background.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
        thumb.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
        title.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
    }else if(direction){
        character_container.addUpdateBehavior(IMMoveIn (  150.0f, vec2(0, size.y), inOutQuartTween ), "");
    }else{
        character_container.addUpdateBehavior(IMMoveIn ( 150.0f, vec2(0, size.y * -1), inOutQuartTween ), "");
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
	if(current_character == -1){
		GetCurrentCharacter();
	}
    if(has_ui){
        if(GetInputDown(0, "mousescrolldown") && !EditorModeActive()){
            direction = true;
    		new_character = min(current_character_ui+1, characters.size() -1);
    	} else if(GetInputDown(0, "mousescrollup") && !EditorModeActive()){
            direction = false;
            new_character = max(0, current_character_ui-1);
    	}
		if(new_character != current_character_ui){
			current_character_ui = new_character;
			int sound_id = PlaySound("Data/Sounds/whoosh/hit_whoosh_2.wav");
			SetSoundGain(sound_id, 0.05);
			SetSoundPitch(sound_id, RangedRandomFloat(0.85, 1.25));
			RefreshUI();
		}
		if(GetInputPressed(0, "f2")){
            RemoveUI();
            fade_in = true;
            has_ui = false;
			if(current_character != current_character_ui){
				current_character = current_character_ui;
				SwitchToCharacter();
			}
		}
    }else if(!EditorModeActive()){
        if(GetInputPressed(0, "f2")){
            AddUI();
            fade_in = false;
            has_ui = true;
        }
    }
    imGUI.update();
}

void SwitchToCharacter(){
    int player_id = GetPlayerCharacterID();
    if(player_id == -1){
        return;
    }
    Object@ player = ReadObjectFromID(player_id);
    MovementObject@ player_mo = ReadCharacterID(player_id);
	player_mo.Execute("SwitchCharacter(\"" + characters[current_character].character_path + "\");");
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
