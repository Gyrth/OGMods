#include "threatcheck.as"
int num_chars = 0;
int play_count = 0;
int splat_count = 0;
float time = 0.0f;
// Called by level.cpp at start of level
void Init(string str) {

}

// This script has no need of input focus
bool HasFocus(){
    return false;
}

// This script has no GUI elements
void DrawGUI() {
}

void Update() {
MovementObject@ char = ReadCharacter(num_chars);
time += time_step;
if(time>=play_count*190){	//Every 190 seconds, which is the duration of the rain audio file, it is played.
	PlaySound("Data/Custom/gyrth/rain/Sounds/rain_track.wav");
	play_count++;
}
		vec3 character_point(char.position.x-RangedRandomFloat(-15.0f,15.0f),char.position.y+30,char.position.z-RangedRandomFloat(-15.0f,15.0f));
		MakeParticle("Data/Custom/gyrth/rain/Particles/rain.xml",character_point,
				vec3(RangedRandomFloat(-5.0f,5.0f),RangedRandomFloat(-50.0f,-100.0f),RangedRandomFloat(-5.0f,5.0f)));
		MakeParticle("Data/Custom/gyrth/rain/Particles/rain.xml",character_point,
				vec3(RangedRandomFloat(-5.0f,5.0f),RangedRandomFloat(-50.0f,-100.0f),RangedRandomFloat(-5.0f,5.0f)));
		if(time>=splat_count*5){	//Every 5 seconds the decals will be removed.
			ClearTemporaryDecals();
			splat_count++;
		}
		UpdateMusic();	//This needs to be added for the OG music.
}
void UpdateMusic() {
    int player_id = GetPlayerCharacterID();
    if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
        PlaySong("sad");
        return;
    }
    int threats_remaining = ThreatsRemaining();
    if(threats_remaining == 0){
        PlaySong("ambient-happy");
        return;
    }
    if(player_id != -1 && ReadCharacter(player_id).QueryIntFunction("int CombatSong()") == 1){
        PlaySong("combat");
        return;
    }
    PlaySong("ambient-tense");
}