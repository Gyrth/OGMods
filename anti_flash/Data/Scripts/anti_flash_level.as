
float black_vignette_base = 1.0f;
float red_fade_duration = 0.4f;
float red_fade_alpha = 0.25f;
vec3 red_fade_color  = vec3(1.0f, 0.0f, 0.0f);

const string BLOCK_PATH = "Data/Objects/anti_flash_block.xml";
const string TABLE_PATH = "Data/Objects/anti_flash_table.xml";
const string SMALL_TABLE_PATH = "Data/Objects/anti_flash_small_table.xml";
const string DOOR_PATH = "Data/Objects/anti_flash_door.xml";
const string DYNAMIC_LIGHT_PATH = "Data/Objects/lights/dynamic_light.xml";

array<int> object_ids;
array<int> refresh_children;
int refresh_counter = 0;

bool post_init_done = false;
float black_vignette_added = 0.0f;
float red_vignette_amount = 0.0f;
float red_fade_start;
float red_fade_end = -1.0f;

void Init(string level_name){

}

void Update(){
    RefreshChildren();
    PostInit();

    if(GetInputPressed(0, "b")){
        DeleteLevel();
    }

    red_vignette_amount = 0.0;
    black_vignette_added = -1.0;
}

void PostInit(){
    if(post_init_done)return;

    BuildLevel();
    MovePlayer();

    post_init_done = true;
}

void RefreshChildren(){
    if(refresh_counter > 0){
        refresh_counter -= 1;
    }else if(refresh_children.size() > 0){

        if(ObjectExists(refresh_children[0])){
            Object@ child = ReadObjectFromID(refresh_children[0]);
            child.SetTranslation(child.GetTranslation());
        }

        refresh_children.removeAt(0);
    }
}

void BuildLevel(){
    vec2 random_level_scale = vec2(RangedRandomFloat(5.0, 10.0), RangedRandomFloat(5.0, 10.0));

    //Create floor.
    int floor_id = CreateObject(BLOCK_PATH);
    Object@ floor = ReadObjectFromID(floor_id);
    floor.SetScale(vec3(random_level_scale.x, 1.0, random_level_scale.y));
    floor.SetTranslation(vec3(0.0, -1.0, 0.0));
    object_ids.insertLast(floor_id);

    //Create ceiling.
    int ceiling_id = CreateObject(BLOCK_PATH);
    Object@ ceiling = ReadObjectFromID(ceiling_id);
    vec3 ceiling_scale = floor.GetScale();
    // ceiling_scale.x = 2.0;
    ceiling.SetScale(ceiling_scale);
    ceiling.SetTranslation(vec3(0.0, 6.0, 0.0));
    object_ids.insertLast(ceiling_id);

    //Create walls.
    array<vec2> directions = {vec2(1, 0), vec2(-1, 0), vec2(0, 1), vec2(0, -1)};
    uint door_wall = rand() % 4;

    for(uint i = 0; i < directions.size(); i++){
        vec2 direction = directions[i];
        float wall_thickness = 0.5;
        int wall_id = CreateObject(BLOCK_PATH);
        Object@ wall = ReadObjectFromID(wall_id);

        vec3 wall_scale = vec3(random_level_scale.x * abs(direction.y), 2.5, random_level_scale.y * abs(direction.x));
        wall_scale.x = max(wall_thickness, wall_scale.x);
        wall_scale.z = max(wall_thickness, wall_scale.z);
        wall.SetScale(wall_scale);
        wall.SetTranslation(vec3((random_level_scale.x + wall_thickness) * direction.x, 2.5, (random_level_scale.y + wall_thickness) * direction.y));

        if(door_wall == i){
            vec3 position = wall.GetTranslation() + vec3(0.0, -1.5, 0.0);
            // Move the door away from the wall.
            position -= vec3(wall_thickness * direction.x, 0.0, wall_thickness * direction.y) * 0.9;

            float wall_offset = 0.5;
            position += vec3(direction.y * RangedRandomFloat(-random_level_scale.x + wall_offset, random_level_scale.x - wall_offset), 0.0, direction.x * RangedRandomFloat(-random_level_scale.y + wall_offset, random_level_scale.y - wall_offset));

            //Create door.
            int door_id = CreateObject(DOOR_PATH);
            Object@ door = ReadObjectFromID(door_id);

            float cur_rotation = atan2(direction.x, direction.y);
            quaternion rotation(vec4(0,1,0,cur_rotation));
            door.SetTranslationRotationFast(position, rotation);

            vec3 base_scale = door.GetScale();
            // Use a slightly bigger scale to trigger an AABB change.
            door.SetScale(base_scale + vec3(0.001));

            array<int> children = door.GetChildren();
            for(uint j = 0; j < children.size(); j++){
                refresh_children.insertLast(children[j]);
            }

            object_ids.insertLast(door_id);
        }

        object_ids.insertLast(wall_id);
    }

    //Create tables.
    for(uint i = 0; i < 5; i++){
        vec3 position = vec3(RangedRandomFloat(-random_level_scale.x, random_level_scale.x), 0.4, RangedRandomFloat(-random_level_scale.y, random_level_scale.y));
        string path;

        switch(rand() % 2){
            case 0:
                path = TABLE_PATH;
                break;
            default:
                path = SMALL_TABLE_PATH;
                break;
        }

        int table_id = CreateObject(path);
        Object@ table = ReadObjectFromID(table_id);

        float x;
        float z;
        switch(rand() % 4){
            case 0:
                x = 1.0f;
                z = 0.0f;
                break;
            case 1:
                x = 0.0f;
                z = 1.0f;
                break;
            case 2:
                x = -1.0f;
                z = 0.0f;
                break;
            default:
                x = 0.0f;
                z = -1.0f;
                break;
        }

        float cur_rotation = atan2(x, z);
        quaternion rotation(vec4(0,1,0,cur_rotation));
        table.SetTranslationRotationFast(position, rotation);

        vec3 base_scale = table.GetScale();
        table.SetScale(vec3(base_scale.x * RangedRandomFloat(0.5, 1.5), base_scale.y, base_scale.z * RangedRandomFloat(0.5, 1.5)));

        array<int> children = table.GetChildren();
        for(uint j = 0; j < children.size(); j++){
            refresh_children.insertLast(children[j]);
        }

        object_ids.insertLast(table_id);
    }

    //Create lights.
    for(uint i = 0; i < 25; i++){
        vec3 position = vec3(RangedRandomFloat(-random_level_scale.x, random_level_scale.x), RangedRandomFloat(0.0, 5.0), RangedRandomFloat(-random_level_scale.y, random_level_scale.y));

        int light_id = CreateObject(DYNAMIC_LIGHT_PATH);
        Object@ light = ReadObjectFromID(light_id);
        light.SetTranslation(position);
        light.SetScale(vec3(RangedRandomFloat(1.0, 15.0)));
        // light.SetTint(vec3(RangedRandomFloat(-10.0, 25.0)));
        // light.SetTint(vec3(RangedRandomFloat(-5.0, 5.0)));
        light.SetTint(vec3(RangedRandomFloat(0.0, 5.0)));

        object_ids.insertLast(light_id);
    }

    refresh_counter = 5;

}

void MovePlayer(){
    for(int i = 0; i < GetNumCharacters(); i++){
        MovementObject@ char = ReadCharacter(i);
        if(char.is_player){
            char.position = vec3(0.0, 1.5, 0.0);
            break;
        }
    }
}

void DeleteLevel(){

    for(uint i = 0; i < object_ids.size(); i++){
        QueueDeleteObjectID(object_ids[i]);
    }

    object_ids.resize(0);
    post_init_done = false;
}

void DrawGUI(){
	if(EditorModeActive()){
		return;
	}

	float width = GetScreenWidth();
	float height = GetScreenHeight();

	if(red_fade_end != -1.0f){
		// Slowly blend from a value of 0.0 to 1.0 to create a smooth red death overlay.
		float blend_progress = min(1.0, 1.0 - ((red_fade_end - the_time) / (red_fade_end - red_fade_start)));
		HUDImage @diffuse_image = hud.AddImage();
		// This texture is completely white and can be tinted red or any color for that matter.
		diffuse_image.SetImageFromPath("Data/Textures/diffuse.tga");
		diffuse_image.position.y = 0.0f;
		diffuse_image.position.x = 0.0f;
		diffuse_image.position.z = -2.0f;
		// Scale the image so it covers the whole screen.
		diffuse_image.scale = vec3(width / diffuse_image.GetWidth(), height / diffuse_image.GetHeight(), 1.0);
		diffuse_image.color = vec4(red_fade_color.x, red_fade_color.y, red_fade_color.z, blend_progress * red_fade_alpha);
	}
	
	float black_vignette_amount = black_vignette_base + black_vignette_added;

	HUDImage @black_vignette_image = hud.AddImage();
	black_vignette_image.SetImageFromPath("Data/Textures/fps_vignette_black.tga");
	black_vignette_image.position.y = 0.0f;
	black_vignette_image.position.x = 0.0f;
	black_vignette_image.position.z = -5.0f;
	black_vignette_image.scale = vec3(width / black_vignette_image.GetWidth(), height / black_vignette_image.GetHeight(), 1.0);
	black_vignette_image.color = vec4(0.0f, 0.0f, 0.0f, black_vignette_amount);

	HUDImage @red_vignette_image = hud.AddImage();
	red_vignette_image.SetImageFromPath("Data/Textures/fps_vignette_white.tga");
	red_vignette_image.position.y = 0.0f;
	red_vignette_image.position.x = 0.0f;
	red_vignette_image.position.z = -4.0f;
	red_vignette_image.scale = vec3(width / red_vignette_image.GetWidth(), height / red_vignette_image.GetHeight(), 1.0);
	red_vignette_image.color = vec4(1.0f, 0.0f, 0.0f, red_vignette_amount);
}