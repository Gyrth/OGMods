int findID(string namez){
      array<int> @object_ids = GetObjectIDs();
      int num_objects = object_ids.length();
      for(int i=0; i<num_objects; ++i){
            Object @obj = ReadObjectFromID(object_ids[i]);
            ScriptParams@ paramss = obj.GetScriptParams();
            if(paramss.HasParam("Name")){
                  if(paramss.GetString("Name") == namez){
                        return object_ids[i];
                  }
            }
      }
      return -1;
}



void Init() {

}


void SetParameters() {
params.AddInt("Eaten", 0);	
params.AddInt("Open", 0);	
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
	params.SetInt("Open", 1);
      if(!mo.controlled){
            if(mo.GetID() != -1){
            OnEnter(mo);
            }
      }
    } else if(event == "exit"){
	 params.SetInt("Open", 0);
       OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
      if(!mo.controlled){
// find the ids of the other wall navs
      int nav1ID = findID("wallNav1");
      int nav2ID = findID("wallNav2");
      int nav3ID = findID("wallNav3");
      int nav4ID = findID("wallNav4");
      Object @obj = ReadObjectFromID(mo.GetID());
      ScriptParams@ paramzz = obj.GetScriptParams();
 		//level.SendMessage("displaytext \""+" dog just got to hotspot "+hotspot.GetID());
 		if(params.GetString("Name") == "wallNav1"){
 			int dice = (rand()%2)+1;
                  if(dice == 1){
 				mo.Execute("Object@ nav_obj = ReadObjectFromID("+nav2ID+");" +
 				"vec3 pos = vec3(floor(nav_obj.GetTranslation().x),floor(nav_obj.GetTranslation().y),floor(nav_obj.GetTranslation().z));" +
            	     "SetGoal(_investigate);" +
            	      
            	     " nav_target = pos;");
                  }else if(dice == 2){
                        mo.Execute("Object@ nav_obj = ReadObjectFromID("+nav4ID+");" +
                        "vec3 pos = vec3(floor(nav_obj.GetTranslation().x),floor(nav_obj.GetTranslation().y),floor(nav_obj.GetTranslation().z));" +
                        "SetGoal(_investigate);" +
                       
                        " nav_target = pos;");
                  }
 		}else if(params.GetString("Name") == "wallNav2"){
                  int dice = (rand()%2)+1;
                  if(dice == 1){
                        mo.Execute("Object@ nav_obj = ReadObjectFromID("+nav1ID+");" +
                        "vec3 pos = vec3(floor(nav_obj.GetTranslation().x),floor(nav_obj.GetTranslation().y),floor(nav_obj.GetTranslation().z));" +
                       "SetGoal(_investigate);" +
                         
                       " nav_target = pos;");
                  }else if(dice == 2){
                        mo.Execute("Object@ nav_obj = ReadObjectFromID("+nav3ID+");" +
                        "vec3 pos = vec3(floor(nav_obj.GetTranslation().x),floor(nav_obj.GetTranslation().y),floor(nav_obj.GetTranslation().z));" +
                        "SetGoal(_investigate);" +
                        
                        " nav_target = pos;");
                  }
 		}else if(params.GetString("Name") == "wallNav3"){
                  int dice = (rand()%2)+1;
                  if(dice == 1){
                        mo.Execute("Object@ nav_obj = ReadObjectFromID("+nav4ID+");" +
                        "vec3 pos = vec3(floor(nav_obj.GetTranslation().x),floor(nav_obj.GetTranslation().y),floor(nav_obj.GetTranslation().z));" +
                       "SetGoal(_investigate);" +
                      
                       " nav_target = pos;");
                  }else if(dice == 2){
                        mo.Execute("Object@ nav_obj = ReadObjectFromID("+nav2ID+");" +
                        "vec3 pos = vec3(floor(nav_obj.GetTranslation().x),floor(nav_obj.GetTranslation().y),floor(nav_obj.GetTranslation().z));" +
                        "SetGoal(_investigate);" +
                     
                        " nav_target = pos;");
                  }
            }else if(params.GetString("Name") == "wallNav4"){
                  int dice = (rand()%2)+1;
                  if(dice == 1){
                        mo.Execute("Object@ nav_obj = ReadObjectFromID("+nav1ID+");" +
                        "vec3 pos = vec3(floor(nav_obj.GetTranslation().x),floor(nav_obj.GetTranslation().y),floor(nav_obj.GetTranslation().z));" +
                       "SetGoal(_investigate);" +
                       
                       " nav_target = pos;");
                  }else if(dice == 2){
                        mo.Execute("Object@ nav_obj = ReadObjectFromID("+nav3ID+");" +
                        "vec3 pos = vec3(floor(nav_obj.GetTranslation().x),floor(nav_obj.GetTranslation().y),floor(nav_obj.GetTranslation().z));" +
                        "SetGoal(_investigate);" +
                       
                        " nav_target = pos;");
                  }
            }
      } 
}

void OnExit(MovementObject @mo) {

}

void Update(){

}

