#include "ui_tools.as"

float UpdateVisible(float visible, float target_visible) {
    return mix(visible, target_visible, 0.1f);
}



class RibbonBackground {
    IMUIContextWrapper imuicontext;
    int gui_id;
    float display_time;

    void Init(){
        gui_id = -1;
        display_time = 0.0;
    }

    RibbonBackground() {
    }

    ~RibbonBackground() {
    }
    
    void Update(){
        display_time += time_step;
    }
    
    void DrawGUI(float visible){
        IMUIContext@ imui_context = imuicontext.Get();
        imui_context.UpdateControls();
        if(visible < 0.01){
            return;
        }
        float ui_scale = 0.5f;
        {   HUDImage @image = hud.AddImage();
            image.SetImageFromPath("Data/Textures/ui/challenge_mode/red_gradient_border_c.tga");
            image.position.x = 0;
            image.position.y = - image.GetHeight() * ui_scale * ((1.0-visible) + 0.125);
            image.position.z = 2;
            float stretch = GetScreenWidth() / image.GetWidth() / ui_scale;
            image.tex_scale.x = stretch;
            image.tex_scale.y = 1.0;
            image.tex_offset.x += display_time * 0.05;
            image.color = vec4(0.7,0.7,0.7,1.0);
            image.scale = vec3(ui_scale*stretch,ui_scale,1.0);}
          
        {   HUDImage @image = hud.AddImage();
            image.SetImageFromPath("Data/Textures/ui/challenge_mode/red_gradient_border_c.tga");
            image.position.x = 0;
            image.position.y = GetScreenHeight() + image.GetHeight() * ui_scale * ((1.0-visible) + 0.375);
            image.position.z = 2;
            float stretch = GetScreenWidth() / image.GetWidth() / ui_scale;
            image.tex_scale.x = stretch;
            image.tex_scale.y = 1.0;
            image.tex_offset.x = display_time * 0.05;
            image.color = vec4(0.7,0.7,0.7,1.0); 
            image.scale = vec3(ui_scale*stretch,-ui_scale,1.0);}
            /*
        {   HUDImage @image = hud.AddImage();
            image.SetImageFromPath("Data/Textures/ui/challenge_mode/giometric_ribbon_c.tga");
            float stretch = GetScreenHeight() / image.GetHeight() / ui_scale;
            image.position.x = GetScreenWidth() * 0.5 - image.GetWidth() * ui_scale * 0.9;
            image.position.y =  ((1.0-visible) * GetScreenHeight() * 1.2);
            image.position.z = 3;
            image.color = vec4(0,0,0,1);
            image.tex_scale.y = stretch;
            image.tex_offset.y = display_time * 0.025;
            image.scale = vec3(ui_scale, ui_scale*stretch, 1.0);}
*/

        
        {   HUDImage @image = hud.AddImage();
            image.SetImageFromPath("Data/UI/darkbg.jpg");
            image.position.x = 0;
            image.position.y = 0;
            image.position.z = 0;
            float stretch_x = (GetScreenWidth()+4) / image.GetWidth();
            float stretch_y = (GetScreenHeight()+4) / image.GetHeight();
            image.color.a = 1.0 * visible;
            image.scale = vec3(stretch_x, stretch_y, 1.0);}
    }
}
