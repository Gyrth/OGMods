#include "arrows.as"

class BowAndArrow {
	//Bow and arrow variables.
	float previousTime;
	int aimAnimationID = -1;
	bool shortDrawAnim = false;
	int bowUpDownAnim;
	float start_throwing_time = 0.0f;
	uint32 aimingParticle;
	uint32 miscParticleID;
	bool isAiming = false;
	bool allowAiming = true;
	array<Arrow@> arrows;
	bool longDrawAnim = false;
	float orig_sensitivity = -1.0f;
	float aim_sensitivity = 0.1f;
	bool init_done = Init();

	bool Init(){
		orig_sensitivity = GetConfigValueFloat("mouse_sensitivity");
		return true;
	}

	void HandleBow(){
		ItemObject@ bow_item;

		if(weapon_slots[primary_weapon_slot] != -1 && ReadItemID(weapon_slots[primary_weapon_slot]).GetLabel() == "bow"){
			@bow_item = ReadItemID(weapon_slots[primary_weapon_slot]);
		}else if(weapon_slots[secondary_weapon_slot] != -1 && ReadItemID(weapon_slots[secondary_weapon_slot]).GetLabel() == "bow"){
			@bow_item = ReadItemID(weapon_slots[secondary_weapon_slot]);
		}
		if(bow_item !is null){
			if( isAiming && floor(length(this_mo.velocity)) < 1.0f && on_ground ||
			throw_anim){
				DrawDoubleSting(bow_item);
				vec3 direction = normalize(throw_target_pos - this_mo.position);
				if(!on_ground){
					this_mo.SetRotationFromFacing(normalize(direction + vec3(direction.z * -1.00, 0, direction.x * 1.00)));
				}
			}else{
				DrawSingleString(bow_item);
			}
		}
		if(throw_anim && longDrawAnim){
			TargetClosestEnemy();
		}
		//When the player is aiming, but attacked and started to ragdoll reset the aiming.
		if(isAiming && state == _ragdoll_state){
			isAiming = false;
			allowAiming = false;
			SetConfigValueFloat("mouse_sensitivity", orig_sensitivity);
		}
		if(throw_anim && weapon_slots[primary_weapon_slot] == -1){
			throw_anim = false;
		}
		if(!allowAiming && !WantsToThrowItem()){
			allowAiming = true;
		}
		HandleBowControls();
	}

	void TargetClosestEnemy(){
		float throw_range = 50.0f;
		int target = GetClosestCharacterID(throw_range, _TC_ENEMY | _TC_CONSCIOUS | _TC_NON_RAGDOLL);
		if(target != -1){
			SetTargetID(target);
			throw_target_pos = ReadCharacterID(target).rigged_object().GetAvgIKChainPos("torso");
		}
	}

	void BowAiming(){
		if(!isAiming && sheathe_layer_id == -1 && allowAiming){
			start_throwing_time = time;
			PlaySound("Data/Sounds/draw.wav", this_mo.position);
			isAiming = true;
		}

		if(isAiming){
			if(WantsToSheatheItem()){
				isAiming = false;
				allowAiming = false;
				SetConfigValueFloat("mouse_sensitivity", orig_sensitivity);
				return;
			}

			BoneTransform transform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kHeadIK]]);
			ItemObject@ primaryWeapon = ReadItemID(weapon_slots[primary_weapon_slot]);
			ItemObject@ secondaryWeapon = ReadItemID(weapon_slots[secondary_weapon_slot]);
			vec3 cameraFacing = camera.GetFacing();
			Object@ charObject = ReadObjectFromID(this_mo.GetID());

			quaternion head_rotation = transform.rotation;
			vec3 facing = camera.GetFacing();
			vec3 start = facing * 5.0f;
			//Limited aim enabled.
			vec3 end = vec3(facing.x, max(-0.9, min(0.5f, facing.y)), facing.z) * 30.0f;
			//Collision check for non player objects
			vec3 hit = col.GetRayCollision(camera.GetPos(), camera.GetPos() + end);
			//Collision check for player objects.
			col.CheckRayCollisionCharacters(camera.GetPos(), camera.GetPos() + end);
			SetConfigValueFloat("mouse_sensitivity", aim_sensitivity);

			throw_target_pos = hit;
			if(sphere_col.NumContacts() != 0){
				for(int i = 0; i < sphere_col.NumContacts(); i++){
					const CollisionPoint contact = sphere_col.GetContact(i);
					if(contact.id != this_mo.GetID() && contact.position != vec3(0,0,0) && distance(camera.GetPos(), throw_target_pos) > distance(camera.GetPos() ,contact.position)){
						throw_target_pos = contact.position;
					}
				}
			}
			aimingParticle = MakeParticle("Data/Particles/bow_and_arrow_aim.xml", throw_target_pos, vec3(0));
			fov = max(fov - ((time - start_throwing_time)), 40.0f);

			cam_pos_offset = vec3(cameraFacing.z * -0.5, 0, cameraFacing.x * 0.5);
			int8 flags = _ANM_FROM_START;

			if(floor(length(this_mo.velocity)) < 2.0f && on_ground){
				this_mo.SetAnimation("Data/Animations/r_draw_bow_stance.anm", 20.0f, flags);
				this_mo.rigged_object().anim_client().RemoveLayer(bowUpDownAnim, 20.0f);
				if(this_mo.GetFacing().y > 0){
					bowUpDownAnim = this_mo.rigged_object().anim_client().AddLayer("Data/Animations/r_draw_bow_stance_aim_up.anm",(60*cameraFacing.y),flags);
				}else{
					bowUpDownAnim = this_mo.rigged_object().anim_client().AddLayer("Data/Animations/r_draw_bow_stance_aim_down.anm",-(60*cameraFacing.y),flags);
				}
				if(cameraFacing.y > -1.0f){
					this_mo.SetRotationFromFacing(normalize(cameraFacing + vec3(cameraFacing.z * -0.5, 0, cameraFacing.x * 0.5)));
				}
			}
		}
	}

	void HandleBowControls(){
		if(GetInputPressed(this_mo.controller_id, "debug_misc_action")){
			SwapWeaponHands();
		}
	}

	void BowShoot(){
		if(weapon_slots[primary_weapon_slot] == -1){
			isAiming = false;
		}else{
			this_mo.rigged_object().anim_client().RemoveLayer(bowUpDownAnim, 1.0f);
			true_max_speed = _base_true_max_speed;
			if((time - start_throwing_time) < 0.5f || floor(length(this_mo.velocity)) > 1.0f){
				shortDrawAnim = false;
				longDrawAnim = true;
			}else{
				shortDrawAnim = true;
				longDrawAnim = false;
			}
			Object@ mainArrow = ReadObjectFromID(weapon_slots[primary_weapon_slot]);
			ScriptParams@ arrowParams = mainArrow.GetScriptParams();

			string arrow_type = arrowParams.GetString("Type");
			Arrow @new_arrow;
			if(arrow_type == "flashbang"){
				@new_arrow = FlashBangArrow();
			}else if(arrow_type == "impactexplosion"){
				@new_arrow = ImpactExplosion();
			}else if(arrow_type == "poison"){
				@new_arrow = PoisonArrow();
			}else if(arrow_type == "poisoncloud"){
				@new_arrow = PoisonCloudArrow();
			}else if(arrow_type == "smoke"){
				@new_arrow = SmokeArrow();
			}else if(arrow_type == "timedexplosion"){
				@new_arrow = TimedExplosionArrow();
			}else{
				@new_arrow = StandardArrow();
			}
			new_arrow.arrow_id = weapon_slots[primary_weapon_slot];
			arrows.insertLast(new_arrow);
			going_to_throw_item = true;
			going_to_throw_item_time = time;
			isAiming = false;
		}
		SetConfigValueFloat("mouse_sensitivity", orig_sensitivity);
	}

	void BowShootAnim(){
		int8 flags = 0;
		SetState(_attack_state);
		string draw_type = "empty";
		if(shortDrawAnim){
			draw_type = "Data/Animations/r_draw_bow_short.anm";
		}else{
			PlaySound("Data/Sounds/draw.wav", this_mo.position);
			int number = rand()%3;
			switch(number){
				case 0: draw_type = "Data/Animations/r_draw_bow.anm";break;
				case 1: draw_type = "Data/Animations/r_draw_bow_askew.anm";break;
				case 2: draw_type = "Data/Animations/r_draw_bow_sideways.anm";break;
			}
		}
		throw_anim = false;
		mirrored_stance = false;
		this_mo.SetAnimation(draw_type, 8.0f, flags);
	}

	void BowShootAnimInAir(){
		int8 flags = 0;
		SetState(_movement_state);
		PlaySound("Data/Sounds/draw.wav", this_mo.position);
		throw_knife_layer_id = this_mo.rigged_object().anim_client().AddLayer("Data/Animations/r_draw_bow_running.anm",20.0f,flags);
		throw_anim = true;
	}

	void HandleArrows(){
		for(uint32 i = 0; i < arrows.size(); i++){
			Arrow @current_arrow = arrows[i];
			if(inSlowMo && current_arrow.arrow_id != -1){
				ItemObject@ arrow_item = ReadItemID(current_arrow.arrow_id);
				cam_pos_offset = (arrow_item.GetPhysicsPosition() - this_mo.position);
			}
			current_arrow.Update();
			if(current_arrow.remove){
				arrows.removeAt(i);
				i--;
			}
		}
	}

	void DrawSingleString(ItemObject@ bow){
		mat4 bowTransform = bow.GetPhysicsTransform();
		quaternion bowRotation = QuaternionFromMat4(bowTransform.GetRotationPart());
		DebugDrawLine(bow.GetPhysicsPosition() + (bowRotation * vec3(0.13,-0.70,0)), bow.GetPhysicsPosition() + (bowRotation * vec3(0.13,0.70,0)), vec3(0), _delete_on_update);
	}

	void DrawDoubleSting(ItemObject@ bow){
		mat4 bowTransform = bow.GetPhysicsTransform();
		BoneTransform handTransform = this_mo.rigged_object().GetFrameMatrix(ik_chain_elements[ik_chain_start_index[kLeftArmKey]]);
		quaternion bowRotation = QuaternionFromMat4(bowTransform.GetRotationPart());

		DebugDrawLine(handTransform.origin, bow.GetPhysicsPosition() + (bowRotation * vec3(0.13,0.70,0)), vec3(0), _delete_on_update);
		DebugDrawLine(handTransform.origin, bow.GetPhysicsPosition() + (bowRotation * vec3(0.13,-0.70,0)), vec3(0), _delete_on_update);
	}
}

void ArrowMetalSparks(vec3 pos){
	int num_sparks = 60;
	float speed = 20.0f;
	for(int i = 0; i < num_sparks; i++){
		MakeParticle("Data/Particles/bow_and_arrow_explosion_fire.xml",pos,vec3(RangedRandomFloat(-speed,speed),
		RangedRandomFloat(-speed,speed),
		RangedRandomFloat(-speed,speed)));
	}
}

void ArrowSmoke(vec3 pos){
	int num_smoke = 3;
	float speed = 20.0f;
	for(int i = 0; i < num_smoke; i++){
		MakeParticle("Data/Particles/bow_and_arrow_explosion_smoke.xml",pos,vec3(RangedRandomFloat(-speed,speed),
		RangedRandomFloat(-speed,speed),
		RangedRandomFloat(-speed,speed)));
		MakeParticle("Data/Particles/bow_and_arrow_explosiondecal.xml",pos,vec3(RangedRandomFloat(-speed,speed),
		RangedRandomFloat(-speed,speed),
		RangedRandomFloat(-speed,speed)));
	}
}
