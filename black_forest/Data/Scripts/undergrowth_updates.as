
void WinterUpdate(){
	Object @obj = ReadObjectFromID(player_id);
    ScriptParams@ params = obj.GetScriptParams();
	winter_timer -= time_step;
	if(params.GetInt("Winter") > 0){
		//
		//level.SetScriptParams().HasParam("cold_breath")
        vec3 pos = camera.GetPos();
        float domain_size = 5.0f;
        vec3 scale = vec3(domain_size);
        vec3 movement_vec = pos - g_pos_previous;
        g_elapsed_time += time_step;
        while(g_elapsed_time >= g_time_per_spawn) {
            vec3 offset;
            offset.x = RangedRandomFloat(-scale.x * 2.0f, scale.x * 2.0f);
            offset.y = RangedRandomFloat(-scale.y * 2.0f, scale.y * 2.0f);
            offset.z = RangedRandomFloat(-scale.z * 2.0f, scale.z * 2.0f);

            vec3 initial_position = pos + offset + movement_vec * 300;
            uint32 id = MakeParticle("Data/Particles/snow.xml", initial_position, vec3(0.0f, 0.0f, -25.0f));

            g_elapsed_time -= g_time_per_spawn;
        }
        g_pos_previous = pos;
    }
	if(winter_timer <= 0){
    	MovementObject@ mo = ReadCharacterID(player_id);
		if(params.GetInt("pausez") != 1){
        //no winter mercy for noobs
        if(params.GetInt("noWinter") > 0){
            params.SetInt("noWinter", params.GetInt("noWinter") -1);
        }
		ScriptParams@ level_params = level.GetScriptParams();
        SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
        string jailed = saved_level.GetValue("jailed");
		 //SetHDRWhitePoint(2.0f);
		//MovementObject@ mo = ReadCharacterID(player_id);
		//update chances for forts
		fortChances = 1.0 + params.GetFloat("Forts");
		trinketChances = 0.0 + params.GetFloat("trinketChances");
		winter_timer = 10.0f;
		if(winterIsComing == 0){
			ReadPersistentInfo();
			winterIsComing = 1;
			if(params.GetInt("Winter")> 0){
				if(winter_sound_id == -1){
					//mo.ReceiveMessage("iceBreath");
					//StopSound(summer_sound_id);
					//winterAmbiant
					
					winter_sound_id = 0;
		    		summer_sound_id = -1;
				}
			}
		}
		if(params.GetInt("Winter")> 0){
			params.SetInt("Winter", (params.GetInt("Winter")-1));
			//obj.UpdateScriptParams();
			if(params.GetInt("Winter") > 0 ){
				//--------------
				
				//level_params.SetString("Custom Shader", "#SNOW_EVERYWHERE2 #MISTY2");
				//--------------
				if(params.GetInt("FireNear") < 1){
					//DisplayError("fat stuff", "not close to fire param is"+params.GetInt("NearFire"));
					//level.SendMessage("displaytext \""+"winter is "+params.GetInt("Winter")+" and NearFire is "+params.GetInt("NearFire")+""+"\"");
					int dice = rand()%100;
					if(dice > ((params.GetFloat("Fat")*100)+30)){
						//Glacier
						if(params.GetString("trinketType") == "Glacier" && (rand()% 100 < params.GetInt("trinketPower")*5) ){      
							level.SendMessage("displaytext \""+"Your trinket protected you against the cold!!"+"\"");
							PlaySound("Data/Sounds/trinketProc.wav", mo.position);
                            createTrinketSparks();
						}else{
							if(GetCharWeaponTag(GetCharPrimaryWeapon(mo)) == "purity"){
                                PlaySound("Data/Sounds/purityProc.wav", mo.position);
                                level.SendMessage("clearhud");
                                level.SendMessage("uicue");
                                level.SendMessage("displayhud /Data/UI/Icons/purityProc.png");
                                createTrinketSparks();
                            }else{
                            	if((rand()% 100)< 75){
							    	params.SetInt("Freezing", (params.GetInt("Freezing")+1));
							    	PlaySound("Data/Sounds/ice_foley/bf_ice_heavy_"+((rand()% 3)+1)+".wav", mo.position);
							    	//important
							    	spam = 0;
							    	rogueUI("Freezing");
							    	if(params.GetInt("Freezing")>=7){
										mo.Execute("DropWeapon(); TakeDamage(9999.9f);Ragdoll(_RGDL_INJURED);zone_killed=0;");
								    	//mo.ReceiveMessage("instaDeath");
								    	level.SendMessage("displaytext \""+"You froze to death!!"+"\"");
								    	saved_level.SetValue("fortChances","");
                                    	saved_level.SetValue("jailed", "");
    							    	save_file.WriteInPlace();
							     	}else if(params.GetInt("Freezing") ==4 ){
								    	PlaySound("Data/Sounds/deathWarning.wav", mo.position);
								    	level.SendMessage("displaytext \""+"You are getting really cold, find a camp fire or a shelter quick!!"+"\"");
							     	}else if(params.GetInt("Freezing") ==5 ){
								    	PlaySound("Data/Sounds/deathWarning.wav", mo.position);
								    	level.SendMessage("displaytext \""+"You are freezing to death, find a camp fire or a shelter quick!!"+"\"");
							     	}else if(params.GetInt("Freezing") ==5 ){
								    	PlaySound("Data/Sounds/deathWarning.wav", mo.position);
								    	level.SendMessage("displaytext \""+"You feel your life slipping away, find a camp fire or a shelter or you will die!!!"+"\"");
							     	}
                            	}
                        	}
						}
					}
					obj.UpdateScriptParams();
				}else{
					if(params.GetInt("Freezing") > 0){
						params.SetInt("Freezing", (params.GetInt("Freezing")-1));
						rogueUI("Warming");
					}
				
				}	
			}else{
				if(summer_sound_id == -1){
					//MovementObject@ mo = ReadCharacterID(player_id);
					mo.ReceiveMessage("summerBreath");
					//StopSound(winter_sound_id);
					params.SetInt("Freezing", 0);
					winter_sound_id = -1;
		    		summer_sound_id = 0;
				}
				rogueUI("Sunny");
				spam = 3;

				//level_params.SetString("Custom Shader", "#MISTY2 #ADD_MOON");
				
			}
			obj.UpdateScriptParams();
		}
	}
	}
}
// used to see if the player has thrown its weapon. It is set to 1 within the aschar.
// enemy killed within that time frame are counted as thrown weapon kills
void ThrowFlagUpdate(){
	if(throwFlag_timer > 0){
		throwFlag_timer -= time_step;
		if(throwFlag_timer <= 0){
			Object @obj = ReadObjectFromID(player_id);
			ScriptParams@ params = obj.GetScriptParams();
			params.SetInt("throwFlag",0);
			obj.UpdateScriptParams();
		}
	}
}

void UpdateRogueUi(){
	if(rogueUI_timer <= 0 ){
	level.SendMessage("clearhud");
	}else{
		//tipDelay
		rogueUI_timer -= time_step;
	}
}
// when blessed
//if(params.GetInt("pausez") != 1){
void UpdateBlessing(){
	bless_timer -= time_step;
    if(bless_timer < 0.0f){
    	MovementObject@ mo = ReadCharacterID(player_id);
    	Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		bless_timer = 4.0f;
		//clear last text
		//level.SendMessage("cleartext");
		//get the player object
		if(params.GetInt("pausez") != 1){
		if(params.GetInt("Bless") > 0){
			if(params.GetString("trinketType") != "the Monk" || (rand()% 100 > params.GetInt("trinketPower")*5) ){
				params.SetInt("Bless", (params.GetInt("Bless")-1));
				obj.UpdateScriptParams();
				if(params.GetInt("Bless") <= 0){
					rogueUI("notBlessed");
					spam = 3;
				}
			}	
		}
	}
		
	}
}
//
// deals with the hunters and evasion
//
void UpdateHunting(){
	// check if the player has disturbed the shit enough to get hunted
	huntTimer -= time_step;
    if(huntTimer < 0.0f){

    	Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		MovementObject@ mo = ReadCharacterID(player_id);
    	level.SendMessage("clearhud");
		level.SendMessage("uicue");
    	huntTimer = 30.0f;
    	if(params.GetInt("pausez") != 1){
		if(rand()%100 < params.GetInt("huntFactor") && params.GetInt("huntLevel") <= 0){
				level.SendMessage("clearhud");
				level.SendMessage("uicue");
				params.SetInt("huntFactor", 0);
				level.SendMessage("displaytext \""+" You are being hunted!!! It's time to do what rabbits do and move swiftly.");
				level.SendMessage("displayhud /Data/UI/Icons/hunted.png");
				PlaySound("Data/Sounds/beingHunted.wav", mo.position);
				PlaySound("Data/Sounds/huntingFar.wav", mo.position);
				params.SetInt("huntLevel", (rand()%30)+1);
		}

		obj.UpdateScriptParams();
	
		if(params.GetInt("huntLevel") > 0){
			if(rand()%100 < 35){
				level.SendMessage("clearhud");
				level.SendMessage("uicue");
				// hunting party moves closer
				ScriptParams@ level_params = level.GetScriptParams();
				//only if it is not at night and not raining
				if((params.GetInt("hour") < 20 || params.GetInt("Winter") > 0) && level_params.GetInt("Rain") == 0){
					params.SetInt("huntLevel", params.GetInt("huntLevel") + (rand()%90));
					if(params.GetInt("huntLevel") >= 300){
						//spawn war party
						params.SetInt("huntLevel", 0);
						params.SetInt("huntFactor", 0);
						SendInHunters();
						SendInHunters();
						SendInHunters();
						SendInHunters();
                        SendInHunters();
						//SendInAssassin(player_id);
						PlaySound("Data/Sounds/dogBark"+((rand()%4)+1)+".wav", mo.position);
					}else if(params.GetInt("huntLevel") >= 200){
						// close!!
						level.SendMessage("displaytext \""+"The hunting party is in the same area as you!!!");
						PlaySound("Data/Sounds/huntingClose.wav", mo.position);
						level.SendMessage("displayhud /Data/UI/Icons/huntedClose.png");
					}else if(params.GetInt("huntLevel") >= 100){
						//mid range
						level.SendMessage("displaytext \""+"The hunting party is on your tail and closing!!");
						PlaySound("Data/Sounds/huntingMedium.wav", mo.position);
						level.SendMessage("displayhud /Data/UI/Icons/huntedMid.png");
					}else if(params.GetInt("huntLevel") > 0){
						// oi fkn far mate
						level.SendMessage("displaytext \""+"The hunting party is following your tracks from afar!!");
						PlaySound("Data/Sounds/huntingFar.wav", mo.position);
						level.SendMessage("displayhud /Data/UI/Icons/huntedFar.png");
					}
				obj.UpdateScriptParams();
				}
			}
		}
	}
	}
}
//
// deals with the pursuing on  ther enemy caravan
//
void UpdateCaravan(){
	MovementObject@ mo = ReadCharacterID(player_id);
	caravanTimer -= time_step;
    if(caravanTimer < 0.0f){
		caravanTimer = 30.0f;
		//clear last text
		//level.SendMessage("cleartext");
		//get the player object
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		if(params.GetInt("pausez") != 1){
		if(params.GetInt("caravanStrike") > 5){
			BlockTypeUpdate("Data/Objects/block_trees_45.xml", 5.0);
		}else{
			BlockTypeUpdate("Data/Objects/block_trees_45.xml", 0.001);
		}
		if(rand()%100 < 35){
			if(!params.HasParam("caravanStrike")){
				params.AddInt("caravanStrike", 0);
			}
			if(params.GetInt("caravanStrike") >= 1 ){
				params.SetInt("caravanStrike", (params.GetInt("caravanStrike")-1));
				PlaySound("Data/Sounds/caravan.wav", mo.position);
				level.SendMessage("clearhud");
				level.SendMessage("uicue");
				if(params.GetInt("caravanStrike") == 0 ){
					PlaySound("Data/Sounds/hunted.wav", mo.position);
					level.SendMessage("displaytext \""+" The enemy caravan has escaped.");
					level.SendMessage("displayhud /Data/UI/Icons/caravaning0.png");
					BlockTypeUpdate("Data/Objects/block_trees_45.xml", 0.001);
				}else if(params.GetInt("caravanStrike") <= 3){
					level.SendMessage("displaytext \""+" The enemy caravan is about to escape. Find some tracks in order to get closer!!");
					level.SendMessage("displayhud /Data/UI/Icons/caravaning1.png");
					BlockTypeUpdate("Data/Objects/block_trees_45.xml", 0.001);
				}else if(params.GetInt("caravanStrike") <= 5){
					level.SendMessage("displaytext \""+" You can hear the enemy caravan moving in the distance. Find more tracks to orient yourself then rob these careless fools.");
					level.SendMessage("displayhud /Data/UI/Icons/caravaning2.png");
					BlockTypeUpdate("Data/Objects/block_trees_45.xml", 0.001);
				}else if(params.GetInt("caravanStrike") > 5){
					level.SendMessage("displaytext \""+" The caravan is still in the area but not for long. Find it and take from them what was once ours.");
					level.SendMessage("displayhud /Data/UI/Icons/caravaning3.png");
					BlockTypeUpdate("Data/Objects/block_trees_45.xml", 5.0);
				}
				obj.UpdateScriptParams();

			}
		}
	}
	}
}
//
// deals with being poisoned and slowly dying.. permanetly
//
void UpdatePoison(){
	MovementObject@ mo = ReadCharacterID(player_id);
	poison_timer -= time_step;
    if(poison_timer < 0.0f){
		poison_timer = 9.0f;
		//clear last text
		//level.SendMessage("cleartext");
		//get the player object
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		if(params.GetInt("pausez") != 1){
		if(params.GetInt("Poison") > 0){
			if(params.GetInt("Winter") < 1  || (rand()%100 < 25)){
				params.SetInt("Poison", (params.GetInt("Poison")+1));
				if(spam <= 0){
					level.SendMessage("displayhud /Data/UI/Icons/poisoned.png");
					spam = 3;
				}
				if(params.GetInt("Poison") == 50){
					level.SendMessage("displaytext \""+"The poison is spreading through your veins! Find an antidote or hire a healer soon!"+"\"");
					PlaySound("Data/Sounds/deathWarning.wav", mo.position);
					level.SendMessage("clearhud");
					level.SendMessage("uicue");
					level.SendMessage("displayhud /Data/UI/Icons/poisoned.png");
				}else if(params.GetInt("Poison") == 75){
					level.SendMessage("displaytext \""+"You will not be able to fight this poison for much longer!! Death is awaiting..."+"\"");
					PlaySound("Data/Sounds/deathWarning.wav", mo.position);
					level.SendMessage("clearhud");
					level.SendMessage("uicue");
					level.SendMessage("displayhud /Data/UI/Icons/poisoned.png");
				}
				//level.SendMessage("displaytext \""+" debug: sickness counter  is at "+params.GetInt("Sick"));
				if(params.GetInt("Poison") >= 100){
					mo.Execute("DropWeapon();TakeDamage(9999.9f);Ragdoll(_RGDL_INJURED);zone_killed=0;");
					level.SendMessage("displaytext \""+"You were poisoned to death!!"+"\"");
					SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
					saved_level.SetValue("fortChances","");
                    saved_level.SetValue("jailed", "");
    				save_file.WriteInPlace();
				}
				for(int xx = 0; xx < 5; xx++){
					vec3 initial_position = vec3(mo.position.x , mo.position.y, mo.position.z);
   					uint32 id = MakeParticle("Data/Particles/Undergrowth/poison_cloud.xml", initial_position, vec3(RangedRandomFloat(-50.0f, 50.0f), RangedRandomFloat(-50.0f, 50.0f), RangedRandomFloat(-50.0f, 50.0f)));
				}
				PlaySound("Data/Sounds/poison.wav", mo.position);
			}
			obj.UpdateScriptParams();
		}
	}
		
	}
}
//
// deals with sickness and mostly the slow process of healing out of it
//
void UpdateSickness(){
	MovementObject@ mo = ReadCharacterID(player_id);
	sick_timer -= time_step;
    if(sick_timer < 0.0f){
		sick_timer = 6.0f;
		//clear last text
		//level.SendMessage("cleartext");
		//get the player object
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		if(params.GetInt("pausez") != 1){
		if(params.GetInt("Sick") > 0){
			params.SetInt("Sick", (params.GetInt("Sick")-1));
			obj.UpdateScriptParams();
			//level.SendMessage("displaytext \""+" debug: sickness counter  is at "+params.GetInt("Sick"));
			if(params.GetInt("Sick") == 0){
				rogueUI("Ill");
				spam = 3;
			}
		}
		}		
	}
}
//
// thirst update deals with thirst obv but also a pletora of other things that needs a short timer.
// sorta like a catch all short timer update
//
void UpdateThirst(){
	// update thirst is one of the shortest timer in the 
	// mod and actually used for many other things than thirst
	thirst_timer -= time_step;
    if(thirst_timer < 0.0f){
    	thirst_timer = 4.0f;
		//some declaration
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		MovementObject@ mo = ReadCharacterID(player_id);
		ScriptParams@ level_params = level.GetScriptParams();
        SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
        //if the player has placed a trap
        if(params.GetInt("pausez") != 1){
        if(bombTimer > 0){
        	bombTimer --;
        	if(bombTimer == 0){
        		level.SendMessage("displaytext \""+"Looks like an unlucky fellow just exploded on your fire bomb!!"+"\"");
        		PlaySound("Data/Sounds/distantBoom.wav");
        		bombTimer = -1;
        	}
        }
		//save game state
    	if(noSave == 0){
			crashSave();
			WritePersistentInfo();
		}
		//if it's cold with breath coldness out IF not dedz
        if(saved_level.GetValue("fortChances") != ""){
		  if(params.GetInt("Winter") > 0){
			 mat4 head_transform = mo.rigged_object().GetAvgIKChainTransform("head");
        	   uint32 idz = MakeParticle("Data/Particles/breath_fog.xml",head_transform*vec4(0.0,0.0,0.0,1.0),(head_transform*vec4(0.0f,1.0,0.0f,0.0f)+mo.velocity),vec3(1.0));
		  }
        }
		
		//weather system---------------------------------------------------------------------------------------------------------------------

        if(rand()%200 <= 1 && level_params.GetInt("Rain") == 0 && params.GetInt("noWinter") <= 0){
			if(winter_sound_id == -1){
				//mo.ReceiveMessage("iceBreath");
				PlaySound("Data/Sounds/winterOn.wav", mo.position);
				//StopSound(summer_sound_id);
				//winterAmbiant
				winter_sound_id = 0;
		    	summer_sound_id = -1;
			}
			params.SetInt("Winter", (params.GetInt("Winter")+25));
			rogueUI("Snowing");
		}
		if(params.GetInt("Winter")<= 0){
			if(rand()%100 == 0){
    			if(level_params.GetInt("Rain") == 0){
      				level_params.SetString("GPU Particle Field", "#RAIN");
      				//level_params.SetString("Custom Shader", "#MISTY2 #ADD_MOON");
      				if(rand() % 2 == 0){
          				PlaySoundGroup("Data/Sounds/weather/thunder_strike_mike_koenig.xml");
      				}
      				if(rain_sound_id != -1){
         				StopSound(rain_sound_id);
						//PlaySound("Data/Sounds/rainStop.wav", mo.position);
          				rain_sound_id = -1;
      				}
      				rain_sound_id = PlaySoundLoop("Data/Sounds/weather/rain.wav", 1.0f);
					level_params.SetInt("Rain", 1);
    			}else{
      				if(rain_sound_id != -1){
          				StopSound(rain_sound_id);
						PlaySound("Data/Sounds/rainStop.wav", mo.position);
          				rain_sound_id = -1;
      				}
      				level_params.SetString("GPU Particle Field", "#BUGS");
      				//level_params.SetString("Custom Shader", "#MISTY2 #ADD_MOON");
					level_params.SetInt("Rain", 0);
    			}
			}
		}
		//random thunder
		if(level_params.GetInt("Rain") == 1 && rand()% 10 == 0){
			PlaySound("Data/Sounds/thunder"+(rand()%5)+".wav");
		}
		//----------------------------------------------------------------------------------------------------------------------------------------------------
		// wendigo script ------------------------------------------------------------------------------------------------------------------------------------
		if(wendigoTimer <= 0){
			if(rand()%150 <= 1 && params.GetInt("hour")> 20){
				if(params.GetString("trinketType") == "Wendigo" || (rand()% 100 < params.GetInt("trinketPower")*5) ){	
					 
					PlaySound("Data/Sounds/trinketProc.wav", mo.position);
                    createTrinketSparks();
				}else{
					PlaySound("Data/Sounds/wendigoSpawn.wav", mo.position);
					level.SendMessage("displaytext \""+"There is a Wendigo in the area.. stay hidden and DO NOT MOVE or it is the end of you!!"+"\"");
					level.SendMessage("clearhud");
					level.SendMessage("uicue");
					level.SendMessage("displayhud /Data/UI/Icons/wendigo.png");
					wendigoTimer = (rand()% 30)+5;
				}
			}
		}else{
			wendigoTimer --;
			if(wendigoTimer > 0){
				if(rand()% 100 < 50){
					PlaySound("Data/Sounds/weird"+((rand()% 9)+1)+".wav", mo.position);
				}
			}else{
				level.SendMessage("displaytext \""+"The wendigo has left your area. It is safe to travel now."+"\"");
				PlaySound("Data/Sounds/wendigoDespawn.wav", mo.position);
			}
		}
		//deals with saturation---------------
		float tempSat;
		string tempString;
		if(level_params.GetInt("Rain") > 0){
			if(level_params.GetFloat("Saturation") > 0.6f){
				tempSat = level_params.GetFloat("Saturation") - 0.05f;
				tempString = ""+tempSat;
				level_params.SetFloat("Saturation", tempSat);
			}
		}else if(params.GetInt("Winter") > 0){
			if(level_params.GetFloat("Saturation") > 0.4f){
				tempSat = level_params.GetFloat("Saturation") - 0.05f;
				tempString = ""+tempSat;
				level_params.SetFloat("Saturation", tempSat);
			}
		}else{
			if(level_params.GetFloat("Saturation") < 1.0f){
				tempSat = level_params.GetFloat("Saturation") + 0.05f;
				tempString = ""+tempSat;
				level_params.SetFloat("Saturation", tempSat);
			}
		}
        //---buddy system-------------------------------------------------------------------------------------
        //buddy system
        if(params.GetInt("Buddy") == 1){
            if(buddyAround()){
                if(GetBuddyID() != -1){
                    MovementObject@ buddy_mo = ReadCharacterID(GetBuddyID());
                    Object@ buddy_Obj = ReadObjectFromID(GetBuddyID());
                    if(buddy_mo.GetIntVar("chase_target_id") == -1 || distance(mo.position, buddy_mo.position) > 5.0f){
                        buddy_Obj.QueueScriptMessage("escort_me "+player_id); 
                    }
                }else{
                    level.SendMessage("displayhud /Data/UI/Icons/quest12failed2.png");
                    params.SetInt("Buddy", 0); 
                }
            }else{
                //if not around, set the buddy variable to 0
                params.SetInt("Buddy", 0);
                level.SendMessage("displaytext \""+"You left your companion behind.");
                PlaySound("Data/Sounds/researchFail.wav", mo.position);
                level.SendMessage("clearhud");
                level.SendMessage("uicue");
                obj.UpdateScriptParams();
            }      
            
            obj.UpdateScriptParams();
        }
        if(params.GetInt("questType") == 12 && params.GetInt("questStatus") == 0){
        	if(diplomatAround()){
                MovementObject@ buddy_mo = ReadCharacterID(GetDiplomatID());
                Object@ buddy_Obj = ReadObjectFromID(GetDiplomatID());
                if(buddy_mo.GetIntVar("chase_target_id")== -1 || distance(mo.position, buddy_mo.position) > 5.0f){
                    buddy_Obj.QueueScriptMessage("escort_me "+GetPlayerID()); 
                }
            }else{
                params.SetInt("questStatus", -1);
                PlaySound("Data/Sounds/nay.wav", mo.position);
                level.SendMessage("clearhud");
                level.SendMessage("uicue");
                level.SendMessage("questReset");
                level.SendMessage("displayhud /Data/UI/Icons/quest12failed2.png");
            }
        }   
		//-------------------------------------------------------------------------------------------------------------------------------------------------
		// actual thirst system ---------------------------------------------------------------------------------------------------------------------------
		if(params.HasParam("Water")){
			// reduce food level
			if(level_params.GetInt("Rain") == 0){
                if(rand()% 100 < 75){
                   params.SetInt("Water", (params.GetInt("Water")-1)); 
                }
				
			}
			
			//test food
			if(params.GetInt("Water") >= 75){
				//not hungry and good to go
   				//params.SetFloat("Movement Speed", 1.0f);
				//obj.UpdateScriptParams();
			}else if(params.GetInt("Water") >= 50){
				if(spam <= 0){
					rogueUI("Water");
					spam = 3;
				}else{
					spam --;
				}
			}else if(params.GetInt("Water") >= 25){
				if(spam <= 0){
					rogueUI("Water");
				spam = 3;
				}else{
					spam --;
				}
			}else if(params.GetInt("Water") >= 0){
				if(spam <= 0){
					rogueUI("Water");
				spam = 3;
				}else{
					spam --;
				}
				if(params.GetInt("Water") == 10){
					PlaySound("Data/Sounds/deathWarning.wav");
					level.SendMessage("displaytext \""+"You are about to die of dehydration find something to drink quick!!"+"\"");
			 	}
			}else{
				mo.Execute("DropWeapon();TakeDamage(9999.9f);Ragdoll(_RGDL_INJURED);zone_killed=0;");
				level.SendMessage("displaytext \""+"You died of dehydration!!"+"\"");
				saved_level.SetValue("fortChances","");
                saved_level.SetValue("jailed", "");
    			save_file.WriteInPlace();
			}
		}else{
			 DisplayError("wtf", "No water param found on player");
		}
		}
        obj.UpdateScriptParams();
		AdjustMalus();
	}
}
//
// gives loot after successful mission
//
void UpdateQuestLoot(){
	if(questLoot_timer > 0){
		questLoot_timer -= time_step;
		if(questLoot_timer <= 0){
			//give reward
					Object @obj = ReadObjectFromID(player_id);
					ScriptParams@ params = obj.GetScriptParams();
					MovementObject@ mo = ReadCharacterID(player_id);
					int dice = (rand() % 2);
					int dice2 = (rand() % 3)+1;
					if(dice == 0){
						params.SetInt("Gold", (params.GetInt("Gold")+dice2));
						rogueUI("Gold");
						PlaySound("Data/Sounds/questReward.wav", mo.position);
						level.SendMessage("displaytext \""+"You received gold as a reward."+"\"");
					}else{
						if(params.GetString("trinketType") == "Wisdom" && (rand()% 100 < params.GetInt("trinketPower")*5) ){
							params.SetInt("xp", (params.GetInt("xp")+2));
							PlaySound("Data/Sounds/trinketProc.wav", mo.position);
                            createTrinketSparks();
						}else{
							params.SetInt("xp", (params.GetInt("xp")+1));
						}
						rogueUI("Scroll");
						PlaySound("Data/Sounds/questReward.wav", mo.position);
						level.SendMessage("displaytext \""+"You received a scroll as a reward."+"\"");
					}
			
		}
	}
}
//
// deals with hunger
//
void UpdateHunger(){
	hunger_timer -= time_step;
    if(hunger_timer < 0.0f){

    	//clears the last text, kinda sanity check for removal of lingering text info on the hud that could have been forgotten by my sub par coding abilities
    	level.SendMessage("cleartext");
    	//used to tone down the wated level increased when detected
    	wantedOnce = 0;
		hunger_timer = 7.0f;
		//get the player object
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();

		if(params.GetInt("pausez") != 1){
		//sanity check
		if(params.HasParam("Food")){
			// reduce food level
			if(params.GetString("trinketType") != "Fasting" || (rand()% 100 > params.GetInt("trinketPower")*5) ){				
				if(rand()% 100 < 75){
                    params.SetInt("Food", (params.GetInt("Food")-1));
                }	
			}
			obj.UpdateScriptParams();
			//test food
			if(params.GetInt("Food") >= 100){
				if(spam <= 0){
					level.SendMessage("displaytext \""+"You are stuffed!!"+"\"");
					spam = 3;
				}else{
					spam --;
				}
			}else if(params.GetInt("Food") >= 75 ){
				if(spam <= 0){
					rogueUI("Food");
					spam = 3;
				}else{
					spam --;
				}
			}else if(params.GetInt("Food") >= 50){
				if(spam <= 0){
				rogueUI("Food");
				spam = 3;
				}else{
					spam --;
				}
			}else if(params.GetInt("Food") >= 25){
				if(spam <= 0){
				rogueUI("Food");
				spam = 3;
				}else{
					spam --;
				}
			}else if(params.GetInt("Food") >= 0){
				if(spam <= 0){
				rogueUI("Food");
				spam = 3;
				}else{
					spam --;
				}
			 	if(params.GetInt("Food") == 10){
					MovementObject@ mo = ReadCharacterID(player_id);
					PlaySound("Data/Sounds/deathWarning.wav", mo.position);
					level.SendMessage("displaytext \""+"You are about to die of starvation find something to eat quick!!"+"\"");
			 	}
			}else{
				MovementObject@ mo = ReadCharacterID(player_id);
				mo.Execute("DropWeapon();TakeDamage(9999.9f);Ragdoll(_RGDL_INJURED);zone_killed=0;");
				level.SendMessage("displaytext \""+"You starved to death!!"+"\"");
				SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
				saved_level.SetValue("fortChances","");
                saved_level.SetValue("jailed", "");
    			save_file.WriteInPlace();
			}
		}else{
			 DisplayError("wtf", "No food param found on player");
		}
		}
		AdjustMalus();
	}
}
//
// deals with respawning and the such
//
void UpdateReviving(){
  	MovementObject@ player = ReadCharacterID(player_id);
    if(!EditorModeActive() && player.GetIntVar("knocked_out") != _awake){
		reviveTimer -= time_step;
		if(GetInputPressed(0, "mouse0") && reviveTimer < 0){
			SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
			string fortChances_str = saved_level.GetValue("fortChances");
	 		if(fortChances_str == ""){
	 			level.SendMessage("loadlevel \"" + "Data/Levels/undergrowth_redux.xml" + "\"");
	 		}else{
				reviveTimer = 5.0f;
				rebuild_world = true;
        		Reset();
			}
		}
    }
}
//
// plays sounds based on what weatehr and time it is
//

void UpdateSounds(){
    delay -= time_step;
    if(delay < 0.0f){
        MovementObject@ player = ReadCharacterID(player_id);
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
	   	delay = RangedRandomFloat(5.0, 20.0f);
		vec3 position = player.position + vec3(RangedRandomFloat(-radius, radius),RangedRandomFloat(-radius, radius),RangedRandomFloat(-radius, radius));
		SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
		string jailed = saved_level.GetValue("jailed");
		if (jailed == ""){
			if(params.GetInt("Winter")> 0){
				if(params.GetInt("hour") < 20){
					PlaySound(winterSounds[rand() % winterSounds.size()], position);
				}else{
					PlaySound(nightWinterSounds[rand() % nightWinterSounds.size()], position);	
				}
			}else{
				if(params.GetInt("hour") < 20){
					PlaySound(summerSounds[rand() % summerSounds.size()], position);
				}else{
					PlaySound(nightSummerSounds[rand() % nightSummerSounds.size()], position);	
				}
			}
		}else{
			PlaySound(jailSounds[rand() % jailSounds.size()], position);
		}
    }
}
//
// deals with the tunes
//
void UpdateMusic() {
    int player_id = GetPlayerCharacterID();
	if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
			SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
		if(saved_level.GetValue("fortChances") == ""){
			PlaySong(deathTune);
			return;
		}else{
			PlaySong(sadTune);
			return;	
		}
		
	}

    if(player_id != -1 && ReadCharacter(player_id).QueryIntFunction("int CombatSong()") == 1){
		Object @obj = ReadObjectFromID(player_id);
		MovementObject @mo = ReadCharacter(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		if(params.HasParam("questType")){
			//spy mission
			if((params.GetInt("questType") == 9 && params.GetInt("questKills") == 99)){
				params.SetInt("questStatus", -1);
			}
			// scout mission
			if(params.GetInt("questType") == 3){
				if(params.GetInt("questStatus")==0){
					params.SetInt("questStatus", -1);
               		PlaySound("Data/Sounds/nay.wav", mo.position);
                	level.SendMessage("clearhud");
                	level.SendMessage("uicue");
                	level.SendMessage("questReset");
                	level.SendMessage("displayhud /Data/UI/Icons/quest3failed.png");
                }		
			}
			// trap mission
			if(params.GetInt("questType") == 14){
				if(params.GetInt("questStatus")==0){
					params.SetInt("questStatus", -1);
                	PlaySound("Data/Sounds/nay.wav", mo.position);
                	level.SendMessage("clearhud");
                	level.SendMessage("uicue");
                	level.SendMessage("questReset");
                	level.SendMessage("displayhud /Data/UI/Icons/quest14failed.png");
            	}
			}
		}
		//change the chill tune
		chillTune ="chill"+rand()%10;
        // if in jail gets a wanted level
        SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
        string jailed = saved_level.GetValue("jailed");
        MovementObject@ player_mo = ReadCharacter(player_id);
        if (jailed != ""){
            if(params.HasParam("wanted")){
                if(params.GetFloat("wanted") < 10.0){
                	if(wantedOnce == 0){
                		wantedOnce = 1;
                    	params.SetFloat("wanted", params.GetFloat("wanted")+0.2f);
                    	//make sure it doeswnt get negativr scores
                    	if(params.GetFloat("wanted") < 0.0){
                    		params.SetFloat("wanted", 0.0);	
                    		obj.UpdateScriptParams();
                    	}
                    	//display wanted level to the player
                    	level.SendMessage("clearhud");
                    	level.SendMessage("uicue");
                    	PlaySound("Data/Sounds/wantedUp.wav", player_mo.position);
                    	level.SendMessage("displaytext \""+"your wanted level is now at "+floor(params.GetFloat("wanted")));
                    	level.SendMessage("displayhud /Data/UI/Icons/wantedlevel"+(floor(params.GetFloat("wanted")))+".png");
                	}
                }
            }else{
                level.SendMessage("displaytext \""+"debug: no wanted param found setting up the float during detection");
                params.AddFloat("wanted", 0.0f); 
            }
        }   
        PlaySong(fightTune);
        return;
    }
    PlaySong(chillTune);
}
//
// day night cycle engine , pretty much alterate the time and how the level looks like
//
void dayNightCycle(){
	daytimer -= time_step;
	if(daytimer <= 0){
		postKnocked = 0;
		daytimer = 30.0f;
		Object @obj = ReadObjectFromID(player_id);
		ScriptParams@ params = obj.GetScriptParams();
		MovementObject@ mo = ReadCharacterID(player_id);
		if(params.GetInt("pausez") != 1){
		// day light systrem-------------------------------------------------------------------------------------------------------------------------------
		if(params.GetInt("hour") < 12 && params.GetInt("hour") >= 0 ){ 
		//	level.SendMessage("displaytext \""+" debug: sun super up hour = "+params.GetInt("hour"));
			// - 0.5 per hour
			ScriptParams@ poop = level.GetScriptParams();
			poop.SetFloat("Sky Brightness", 6.0f);
			// - 0.083 per hour
			SetSunAmbient(1.0f);
			// + 5.83 per hour
			SetHDRWhitePoint(0.80f);
			if(wendigoTimer > 0){
				wendigoTimer = 0;
				level.SendMessage("displaytext \""+"The sunlight has chased the wendigo away..."+"\"");
				PlaySound("Data/Sounds/wendigoDespawn.wav", mo.position);
			}
		}else if(params.GetInt("hour") >= 12 ){
			//level.SendMessage("displaytext \""+" debug: sun going down hour = "+params.GetInt("hour"));
			SetHDRWhitePoint(0.80f+((params.GetInt("hour")-12)*0.0583));
			//sky teint
			 if(params.GetInt("hour") < 15){
				SetSkyTint(vec3(164.0f, 97.0f, 18.0f));
				SetSunAmbient(0.6f);
			}else if(params.GetInt("hour") < 20){
				SetSkyTint(vec3(9.0f, 76.0f, 67.0f));
				SetSunAmbient(0.3f);
			}else {
				SetSkyTint(vec3(0.0f, 0.0f, 0.0f));
				SetSunAmbient(0.0f);
				//poop.SetFloat("Sky Brightness", 0.0f);
			}
		}
		if(params.GetInt("hour") > 24 ){

			if(params.GetInt("day") == 0){
				params.SetInt("day",1);
			}else{
				params.SetInt("day",0);
			}
		}
		if(params.GetInt("hour") < 0){
			params.SetInt("hour", 0);
			obj.UpdateScriptParams();
			if(params.GetInt("day") == 0){
				params.SetInt("day",1);
			}else{
				params.SetInt("day",0);
			}
		}
		if(params.HasParam("day")){
			if(params.GetInt("day") == 0){
				//going towards the night
				params.SetInt("hour", params.GetInt("hour")+1);
			}else{
				//going towards the day
				params.SetInt("hour", params.GetInt("hour")-1);
			}
		}else{
			params.AddInt("day", 0);
			params.AddInt("hour", 0);
		}
        // jail wanted level update-----------------------------------------------------------------------------------------------------------
        if(rand()%100 < 50){
            SavedLevel @saved_level = save_file.GetSavedLevel(level_name);
            string jailed = saved_level.GetValue("jailed");
            if (jailed != ""){
                if(params.HasParam("wanted")){
                    if(params.GetFloat("wanted") >= 1.0){
                        params.SetFloat("wanted", params.GetFloat("wanted")-1.0);
                        PlaySound("Data/Sounds/wantedDown.wav", mo.position);
                        level.SendMessage("clearhud");
                        level.SendMessage("uicue");
                    }else{
						params.SetFloat("wanted", 0.0);
                        PlaySound("Data/Sounds/wantedDown.wav", mo.position);
                        level.SendMessage("clearhud");
                        level.SendMessage("uicue");
                    }
                    obj.UpdateScriptParams();
                }else{
                    //level.SendMessage("displaytext \""+"debug: no wanted param found setting up the float during wanted cooldown");
                    params.AddFloat("wanted", 0.0f); 
                }
                level.SendMessage("displayhud /Data/UI/Icons/wantedlevel"+(floor(params.GetFloat("wanted")))+".png"); 
            }  
            
        }
    	}
		obj.UpdateScriptParams();
	}
}