bool show = false;
int chosen_item = 0;
array<string> language_options = {"en", "fr-fr"};
string current_language = "";

void DrawGUI() {
    Display();
}

void Init(string str){
    LoadLanguage();
    level.Execute("dialogue.SetLanguage(\"" + current_language + "\");");
}

void Display(){
    if(show){
        ImGui_Begin("Language Selection", show, ImGuiWindowFlags_NoScrollbar);
        ImGui_Combo("Language", chosen_item, language_options);

        if(ImGui_Button("Choose")) {
            current_language = language_options[chosen_item];
            level.Execute("dialogue.SetLanguage(\"" + current_language + "\");");
            Log(info, "choose " + current_language + " " + chosen_item);
            SaveLanguage();
            show = false;
        }
        if (!show){
            if (!EditorEnabled()){
                level.Execute("has_gui = false;");
            }
        }
        ImGui_End();
    }
}

void ReceiveMessage(string msg){
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "set_animation"){

    }
}

void SaveLanguage(){
    SavedLevel@ global_save = save_file.GetSave("","global","");
    global_save.SetValue("language", current_language);
    save_file.WriteInPlace();
}

void LoadLanguage(){
    SavedLevel@ global_save = save_file.GetSave("","global","");
    current_language = global_save.GetValue("language");
    for (uint i = 0; i < language_options.size(); i++){
        if(language_options[i] == current_language){
            chosen_item = i;
            Log(info, "Current index " + chosen_item);
            Log(info, "Language " + current_language);
        }
    }
}

void Update(){
    if(GetInputDown(0, "l") && GetInputDown(0, "lctrl") ){
        if (!show){
            LoadLanguage();
            level.Execute("has_gui = true;");
        }
        show = true;
    }
}

bool HasFocus(){
    return false;
}
