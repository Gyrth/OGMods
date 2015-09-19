#include "threatcheck.as"
uint64 global_time; // in ms
float falingtoofast = -10;
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
	int num_chars = GetNumCharacters();
	for(int i=0; i<num_chars; ++i){
    MovementObject@ char = ReadCharacter(i);
	time += time_step;
	//A check so snow only appears on player characters.
	if(char.controlled){
			//The characters velocity changes the spawn position of the particles.
			vec3 character_point(char.position.x+(char.velocity.x*1.5)-RangedRandomFloat(-15.0f,15.0f),char.position.y+17,char.position.z+(char.velocity.z*1.5)-RangedRandomFloat(-15.0f,15.0f));
			//If the character falls too fast the particles spawn below.
			if (char.velocity.y<falingtoofast){
			vec3 character_point(char.position.x+(char.velocity.x*1.5)-RangedRandomFloat(-15.0f,15.0f),char.position.y-RangedRandomFloat(5.0f,15.0f),char.position.z+(char.velocity.z*1.5)-RangedRandomFloat(-15.0f,15.0f));
			MakeParticle("Data/Custom/gyrth/snow/Particles/snow.xml",character_point,
					vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-5.0f,-15.0f),RangedRandomFloat(-2.0f,2.0f)));
			MakeParticle("Data/Custom/gyrth/snow/Particles/snow_with_decal.xml",character_point,
					vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-5.0f,-15.0f),RangedRandomFloat(-2.0f,2.0f)));
			break;
			}
			MakeParticle("Data/Custom/gyrth/snow/Particles/snow.xml",character_point,
					vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-5.0f,-15.0f),RangedRandomFloat(-2.0f,2.0f)));
			MakeParticle("Data/Custom/gyrth/snow/Particles/snow_with_decal.xml",character_point,
					vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-5.0f,-15.0f),RangedRandomFloat(-2.0f,2.0f)));
			if(time>=splat_count*5){	//Every 5 seconds the decals will be removed.
				ClearTemporaryDecals();
				splat_count++;
			}
		}
				UpdateMusic();	//This needs to be added for the OG music.

	}
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
