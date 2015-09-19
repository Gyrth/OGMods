float time = 0.0f;
float timedropdoor = 0.0f;
float timedropdoorindie = 0.0f;
float timewolfheadbleeds= 0.0f;
bool playdropdoorsound = false;
bool dropdropdoor = false;
bool wolfheadbleeds = false;

string message;
string substr;
int objid;
int dropdoorid = 600;
int idiedoorid = 0;
bool beeninit = false;
int platenumber;
int platespusheddown = 1;
bool move = false;
string upordown;
bool upordownbool = false;
bool indimove = false;
vec3 posplateone;
vec3 posplatetwo;
vec3 posplatethree;
vec3 posplatefour;
vec3 posplatefive;
void Init(string str) {

}
bool HasFocus(){
    return false;
}

void ReceiveMessage(string msg) {
	Object@ firstPlateObj = ReadObjectFromID(500);
	Object@ secondPlateObj = ReadObjectFromID(501);
	Object@ thirdPlateObj = ReadObjectFromID(502);
	Object@ fourthPlateObj = ReadObjectFromID(503);
	Object@ fifthPlateObj = ReadObjectFromID(504);
	if (beeninit == false){
	beeninit = true;
	posplatefive = fifthPlateObj.GetTranslation();
	posplateone = firstPlateObj.GetTranslation();
	posplatetwo = secondPlateObj.GetTranslation();
	posplatethree = thirdPlateObj.GetTranslation();
	posplatefour = fourthPlateObj.GetTranslation();
	}
	if (move == false){
	message = msg;
	TokenIterator token_iter;
	token_iter.Init();
		if(!token_iter.FindNextToken(message)){
			return;
		}
	string token = token_iter.GetToken(message);
	substr = token.substr(0, 7);
	objid = parseInt(token.substr(7,3));
	upordown = token.substr(10, 2);
	platenumber = parseInt(token.substr(12, 1));
	//Print("Token: "+token+"\n");
	//Print("what to do: "+substr+"\n");
	//Print("OBJ ID: "+objid+"\n");
	//Print("upordown: "+upordown+"\n");
	//Print("Plate Number: "+platenumber+"\n");
	//Print("platespusheddown: "+platespusheddown+"\n");
		if(substr == "moveobj"){
			if(platenumber == platespusheddown){
				platespusheddown++;
				Object@ moveObj = ReadObjectFromID(objid);
				move = true;
				vec3 move = moveObj.GetTranslation();
				PlaySound("Data/Custom/gyrth/airtemple/Sound/concrete.wav", move);
				
				}
			else if(platenumber == (platespusheddown-1)){
			}
			else{
				platespusheddown = 1;
				resetPlatesPos(firstPlateObj, secondPlateObj, thirdPlateObj, fourthPlateObj, fifthPlateObj);
				Print("You pressed the wrong plate, and all of them have been reset."+"\n");
			}
		}
		if(substr == "indimov"){
			idiedoorid = objid;
			Object@ moveObj = ReadObjectFromID(objid);
			indimove = true;
			vec3 move = moveObj.GetTranslation();
			PlaySound("Data/Custom/gyrth/airtemple/Sound/concrete.wav", move);
			
		}
	}
}

void DrawGUI() {
}

void Update() {

    if (move == true){
	time += time_step;
	
		if (upordown == "dn"){
			Object@ moveObj = ReadObjectFromID(objid);
			vec3 move = moveObj.GetTranslation();
			move.y = move.y - 0.001;
			moveObj.SetTranslation(move);
			}
		else if (upordown == "up"){
			Object@ moveObj = ReadObjectFromID(objid);
			vec3 move = moveObj.GetTranslation();
			move.y = move.y + 0.001;
			moveObj.SetTranslation(move);
	}
	if(time > 2 && platespusheddown != 6){
			time = 0;
			move = false;
		}
	if(time > 2 && platespusheddown == 6){
			timedropdoor = 0;
			move = false;
			dropdropdoor = true;
		}
	}
	if(dropdropdoor == true){
		timedropdoor += time_step;
		Object@ doorObject = ReadObjectFromID(dropdoorid);
		Object@ hint1 = ReadObjectFromID(187);
		Object@ hint2 = ReadObjectFromID(186);
		Object@ hint3 = ReadObjectFromID(172);
		Object@ hint4 = ReadObjectFromID(188);
		vec3 move = doorObject.GetTranslation();
		vec3 posHint1 = hint1.GetTranslation();
		vec3 posHint2 = hint2.GetTranslation();
		vec3 posHint3 = hint3.GetTranslation();
		vec3 posHint4 = hint4.GetTranslation();
		move.y = move.y - 0.005;
		posHint1.y = posHint1.y - 0.005;
		posHint2.y = posHint2.y - 0.005;
		posHint3.y = posHint3.y - 0.005;
		posHint4.y = posHint4.y - 0.005;
		hint1.SetTranslation(posHint1);
		hint2.SetTranslation(posHint2);
		hint3.SetTranslation(posHint3);
		hint4.SetTranslation(posHint4);
		doorObject.SetTranslation(move);
			if (playdropdoorsound == false){
				PlaySound("Data/Custom/gyrth/airtemple/Sound/dropdoor.wav", move);
				playdropdoorsound = true;
			}
	}
	if(indimove == true){
		timedropdoorindie += time_step;
		Object@ moveObj = ReadObjectFromID(idiedoorid);
		Object@ movePilarObj = ReadObjectFromID(200);
		vec3 move = moveObj.GetTranslation();
		vec3 movePilar = movePilarObj.GetTranslation();
		movePilar.y = movePilar.y - 0.001;
		move.y = move.y - 0.005;
		move.x = move.x - 0.001;
		move.z = move.z + 0.001;
		moveObj.SetTranslation(move);
		movePilarObj.SetTranslation(movePilar);
			if (playdropdoorsound == false){
				PlaySound("Data/Custom/gyrth/airtemple/Sound/dropdoorindie.wav", move);
				playdropdoorsound = true;
			}
	}
	if(timedropdoorindie > 12.0){
		timedropdoor = 0;
			indimove = false;
			playdropdoorsound = false;
			timedropdoorindie = 0.0f;
			
			
			Object@ moveObjHotspot = ReadObjectFromID(183);
			vec3 moveHotsp = moveObjHotspot.GetTranslation();
			moveHotsp.x = moveHotsp.x - 15.00;
			moveObjHotspot.SetTranslation(moveHotsp);
			wolfheadbleeds = true;
		}
	if(timedropdoor > 31.2){
		timedropdoor = 0;
			dropdropdoor = false;
			playdropdoorsound = false;
			timedropdoor = 0.0f;
		}
	if(wolfheadbleeds == true){
		timewolfheadbleeds += time_step;
	}
	if(wolfheadbleeds == true && timewolfheadbleeds > 5.0){
		timewolfheadbleeds = 0.0;
		ItemObject@ io = ReadItemID(181);
		MakeParticle("Data/Custom/gyrth/airtemple/Particles/blooddrop.xml",io.GetPhysicsPosition(),vec3(0.0f,-1.0f,0.0f));
	}
}

void HotspotEnter(string str, MovementObject @mo) {
    if(str == "Stop"){
        level.SendMessage("reset");
    }
}

void HotspotExit(string str, MovementObject @mo) {
}
void resetPlatesPos(Object@ firstPlateObj, Object@ secondPlateObj, Object@ thirdPlateObj, Object@ fourthPlateObj, Object@ fifthPlateObj){
	firstPlateObj.SetTranslation(posplateone);
	secondPlateObj.SetTranslation(posplatetwo);
	thirdPlateObj.SetTranslation(posplatethree);
	fourthPlateObj.SetTranslation(posplatefour);
	fifthPlateObj.SetTranslation(posplatefive);
}
void initObjects(){

}
