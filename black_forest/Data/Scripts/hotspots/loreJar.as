bool g_is_active = false;
string g_image_path;
float g_scale;
vec4 g_tint;
int dice = (rand()%10)+1;
string image_path = "/Data/UI/lore"+dice+".png";

void Init() {
}

float Int255ColorComponentTo1Float(int value) {
    if(value < 0) {
        value = 0;
    }
    if(value > 255) {
        value = 255;
    }
    return value > 0 ? float(value + 1) / 256.0f : 0.0f;
}

void SetParameters() {
    g_image_path = image_path;

    params.AddFloatSlider("[1] Scale", 0.5, "min:0.0,max:1.0,step:0.1,text_mult:100");
    g_scale = params.GetFloat("[1] Scale");

    params.AddIntSlider("[2a] Red Tint", 255, "min:0.0,max:255.0");
    params.AddIntSlider("[2b] Green Tint", 255, "min:0.0,max:255.0");
    params.AddIntSlider("[2c] Blue Tint", 255, "min:0.0,max:255.0");
    params.AddIntSlider("[2d] Alpha Tint", 255, "min:0.0,max:255.0");
    g_tint.x = Int255ColorComponentTo1Float(params.GetInt("[2a] Red Tint"));
    g_tint.y = Int255ColorComponentTo1Float(params.GetInt("[2b] Green Tint"));
    g_tint.z = Int255ColorComponentTo1Float(params.GetInt("[2c] Blue Tint"));
    g_tint.a = Int255ColorComponentTo1Float(params.GetInt("[2d] Alpha Tint"));
}

void Reset() {
    g_is_active = false;
}

void HandleEvent(string event, MovementObject @mo) {
    if(mo.controlled) {
        if(event == "enter") {
            if(g_image_path.length() > 0 && FileExists(g_image_path)) {
                 PlaySound("Data/Sounds/study.wav", mo.position);
                g_is_active = true;
            }
        } else if(event == "exit") {
            g_is_active = false;
        }
    }
}

void Draw() {
    if(g_is_active) {
        HUDImage@ image = hud.AddImage();
        image.SetImageFromPath(g_image_path);

        vec2 screen_dims = vec2(GetScreenWidth(), GetScreenHeight());
        float screen_aspect_ratio = screen_dims.x / screen_dims.y;

        vec2 image_dims = vec2(image.GetWidth(), image.GetHeight());
        float image_aspect_ratio = image_dims.x / image_dims.y;

        float fill_scale = screen_aspect_ratio <= image_aspect_ratio ?
            screen_dims.x / image_dims.x :
            screen_dims.y / image_dims.y;

        float image_scale = g_scale * fill_scale;
        vec2 image_pos = vec2(
            screen_dims.x - (image_dims.x * image_scale),
            screen_dims.y - (image_dims.y * image_scale)) * 0.5f;

        image.scale = vec3(image_scale, image_scale, 0.0f);
        image.position = vec3(image_pos.x, image_pos.y, 0.0f);
        image.color = g_tint;
    }
}
