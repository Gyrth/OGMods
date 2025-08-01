void RemoveUI(){
	cc_ui_added = false;
	level.Execute("has_gui = false;");
	imGUI.getMain().clear();
}

void AddProgressUI(){
	//ui shenanigans
	cc_ui_added = true;
	level.Execute("has_gui = true;");
	vec2 menu_size(1000, 50);
	vec4 background_color(0,0,0,0.5);
	vec2 button_size(1000, 60);
	vec2 option_size(450, 60);
	vec2 connect_button_size(1000, 60);
	float button_size_offset = 5.0f;
	float description_width = 200.0f;
	Object @obj = ReadObjectFromID(player_id);
	ScriptParams@ params = obj.GetScriptParams();
	string myName = params.GetString("playerName");

	IMContainer menu_container(menu_size.x, menu_size.y);
	menu_container.setAlignment(CACenter, CATop);
	IMDivider menu_divider("menu_divider", DOVertical);
	menu_container.setElement(menu_divider);

	menu_divider.appendSpacer(10);

	{
		//Choose a username and character
		IMContainer container(button_size.x, button_size.y);
		menu_divider.append(container);
		IMDivider divider("title_divider", DOHorizontal);
		divider.setZOrdering(3);
		container.setElement(divider);
		IMText title(myName, small_font);
		divider.append(title);
		//Background
		IMImage background(brushstroke_background);
		background.setZOrdering(2);
		background.setClip(false);
		background.setSize(vec2(600, 60));
		background.setAlpha(0.85f);
		container.addFloatingElement(background, "background", vec2(container.getSizeX() / 2.0f - background.getSizeX() / 2.0f,0));
		//
		IMImage sidepic(side_picture);
		sidepic.setZOrdering(2);
		sidepic.setClip(false);
		sidepic.setSize(vec2(298, 648));
		sidepic.setAlpha(1.0f);
		container.addFloatingElement(sidepic, "sidepic", vec2(-300.0f,-10.0f));
		//
		IMImage kungFuBeltPic("UI/Icons/belt"+params.GetInt("KungfuBelt")+".png");
		kungFuBeltPic.setZOrdering(2);
		kungFuBeltPic.setClip(false);
		kungFuBeltPic.setSize(vec2(25, 25));
		kungFuBeltPic.setAlpha(1.0f);
		container.addFloatingElement(kungFuBeltPic, "kungFuBeltPic", vec2(280.0f,680.0f));
		//
		IMImage kenjuBeltPic("UI/Icons/belt"+params.GetInt("KenjutsuBelt")+".png");
		kenjuBeltPic.setZOrdering(2);
		kenjuBeltPic.setClip(false);
		kenjuBeltPic.setSize(vec2(25, 25));
		kenjuBeltPic.setAlpha(1.0f);
		container.addFloatingElement(kenjuBeltPic, "kenjuBeltPic", vec2(480.0f,680.0f));
		//
		IMImage NinjBeltPic("UI/Icons/belt"+params.GetInt("NinjitsuBelt")+".png");
		NinjBeltPic.setZOrdering(2);
		NinjBeltPic.setClip(false);
		NinjBeltPic.setSize(vec2(25, 25));
		NinjBeltPic.setAlpha(1.0f);
		container.addFloatingElement(NinjBeltPic, "NinjBeltPic", vec2(680.0f,680.0f));
		//
		IMImage ShurikenBeltPic("UI/Icons/belt"+params.GetInt("ShurikenBelt")+".png");
		ShurikenBeltPic.setZOrdering(2);
		ShurikenBeltPic.setClip(false);
		ShurikenBeltPic.setSize(vec2(25, 25));
		ShurikenBeltPic.setAlpha(1.0f);
		container.addFloatingElement(ShurikenBeltPic, "ShurikenBeltPic", vec2(880.0f,680.0f));
		//
		IMImage freezinPic("UI/Icons/freezinUI.png");
		freezinPic.setZOrdering(2);
		freezinPic.setClip(false);
		freezinPic.setSize(vec2(25, 25));
		freezinPic.setAlpha(1.0f);
		container.addFloatingElement(freezinPic, "freezinPic", vec2(97.0f,557.0f));
		//
		IMImage poisonPic("UI/Icons/poisonUI.png");
		poisonPic.setZOrdering(2);
		poisonPic.setClip(false);
		poisonPic.setSize(vec2(25, 25));
		poisonPic.setAlpha(1.0f);
		container.addFloatingElement(poisonPic, "poisonPic", vec2(309.0f,557.0f));
		//
		IMImage illPic("UI/Icons/illUI.png");
		illPic.setZOrdering(2);
		illPic.setClip(false);
		illPic.setSize(vec2(25, 25));
		illPic.setAlpha(1.0f);
		container.addFloatingElement(illPic, "illPic", vec2(501.0f,557.0f));
		//
		IMImage huntedPic("UI/Icons/huntedUI.png");
		huntedPic.setZOrdering(2);
		huntedPic.setClip(false);
		huntedPic.setSize(vec2(25, 25));
		huntedPic.setAlpha(1.0f);
		container.addFloatingElement(huntedPic, "huntedPic", vec2(711.0f,557.0f));
		//
		IMImage foodPic("UI/Icons/foodUI.png");
		foodPic.setZOrdering(2);
		foodPic.setClip(false);
		foodPic.setSize(vec2(25, 25));
		foodPic.setAlpha(1.0f);
		container.addFloatingElement(foodPic, "foodPic", vec2(205.0f,440.0f));
		//
		IMImage waterPic("UI/Icons/waterUI.png");
		waterPic.setZOrdering(2);
		waterPic.setClip(false);
		waterPic.setSize(vec2(25, 25));
		waterPic.setAlpha(1.0f);
		container.addFloatingElement(waterPic, "waterPic", vec2(411.0f,438.0f));
		//
		IMImage blessPic("UI/Icons/blessUI.png");
		blessPic.setZOrdering(2);
		blessPic.setClip(false);
		blessPic.setSize(vec2(25, 25));
		blessPic.setAlpha(1.0f);
		container.addFloatingElement(blessPic, "blessPic", vec2(619.0f,438.0f));
		//
		IMImage scavengePic("UI/Icons/scavengeUI.png");
		scavengePic.setZOrdering(2);
		scavengePic.setClip(false);
		scavengePic.setSize(vec2(25, 25));
		scavengePic.setAlpha(1.0f);
		container.addFloatingElement(scavengePic, "scavengePic", vec2(77.0f,318.0f));
		//
		IMImage stealPic("UI/Icons/stealUI.png");
		stealPic.setZOrdering(2);
		stealPic.setClip(false);
		stealPic.setSize(vec2(25, 25));
		stealPic.setAlpha(1.0f);
		container.addFloatingElement(stealPic, "stealPic", vec2(297.0f,318.0f));
		//
		IMImage prayPic("UI/Icons/prayUI.png");
		prayPic.setZOrdering(2);
		prayPic.setClip(false);
		prayPic.setSize(vec2(25, 25));
		prayPic.setAlpha(1.0f);
		container.addFloatingElement(prayPic, "prayPic", vec2(689.0f,318.0f));
		//
		IMImage trackingPic("UI/Icons/trackingUI.png");
		trackingPic.setZOrdering(2);
		trackingPic.setClip(false);
		trackingPic.setSize(vec2(25, 25));
		trackingPic.setAlpha(1.0f);
		container.addFloatingElement(trackingPic, "trackingPic", vec2(499.0f,318.0f));
		//
		//
		IMImage goldPic("UI/Icons/goldUI.png");
		goldPic.setZOrdering(2);
		goldPic.setClip(false);
		goldPic.setSize(vec2(25, 25));
		goldPic.setAlpha(1.0f);
		container.addFloatingElement(goldPic, "goldPic", vec2(131.0f,200.0f));
		//
		IMImage scrollPic("UI/Icons/scrollUI.png");
		scrollPic.setZOrdering(2);
		scrollPic.setClip(false);
		scrollPic.setSize(vec2(25, 25));
		scrollPic.setAlpha(1.0f);
		container.addFloatingElement(scrollPic, "scrollPic", vec2(325.0f,200.0f));
		//
		IMImage pickPic("UI/Icons/pickUI.png");
		pickPic.setZOrdering(2);
		pickPic.setClip(false);
		pickPic.setSize(vec2(25, 25));
		pickPic.setAlpha(1.0f);
		container.addFloatingElement(pickPic, "pickPic", vec2(505.0f,200.0f));
		//
        IMImage mapPic("UI/Icons/mapUI.png");
        mapPic.setZOrdering(2);
        mapPic.setClip(false);
        mapPic.setSize(vec2(25, 25));
        mapPic.setAlpha(1.0f);
        container.addFloatingElement(mapPic, "mapPic", vec2(730.0f,200.0f));
        //
	}

	menu_divider.appendSpacer(5);
	//put the player title there
	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container(description_width, option_size.y);
		IMText description_label("The "+titleReader()+beltReader(), client_connect_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);

		username_divider.appendSpacer(2);
		menu_divider.append(username_container);
	}
	
	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container(description_width, option_size.y);
		IMText description_label("TRAPPINGS", small_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);

		username_divider.appendSpacer(2);
		menu_divider.append(username_container);
	}

	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container(description_width, option_size.y);
		IMText description_label("Gold: "+params.GetInt("Gold"), client_connect_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);
		username_divider.appendSpacer(2);
		//
		IMContainer username_container2(option_size.x, option_size.y);
		IMDivider username_divider2("username_divider", DOHorizontal);
		IMContainer username_parent_container2(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent2("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent2);
		username_container2.setElement(username_divider2);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container2(description_width, option_size.y);
		IMText description_label2("Scrolls: "+params.GetInt("xp"), client_connect_font);
		description_container2.setElement(description_label2);
		description_label2.setZOrdering(3);
		username_divider.append(description_container2);
		username_divider.appendSpacer(2);
		//
		IMContainer username_container3(option_size.x, option_size.y);
		IMDivider username_divider3("username_divider", DOHorizontal);
		IMContainer username_parent_container3(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent3("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent3);
		username_container3.setElement(username_divider3);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container3(description_width, option_size.y);
		IMText description_label3("Lock Picks: "+params.GetInt("lockPick"), client_connect_font);
		description_container3.setElement(description_label3);
		description_label3.setZOrdering(3);
		username_divider.append(description_container3);
		username_divider.appendSpacer(2);
		//
        IMContainer username_container4(option_size.x, option_size.y);
        IMDivider username_divider4("username_divider", DOHorizontal);
        IMContainer username_parent_container4(button_size.x / 2.0f, button_size.y);
        username_parent_container.sendMouseOverToChildren(true);
        username_parent_container.sendMouseDownToChildren(true);
        IMDivider username_parent4("username_parent", DOHorizontal);
        username_parent_container.setElement(username_parent4);
        username_container4.setElement(username_divider4);
        username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
        IMContainer description_container4(description_width, option_size.y);
        IMText description_label4("Map: "+params.GetInt("map")+"%", client_connect_font);
        description_container4.setElement(description_label4);
        description_label4.setZOrdering(3);
        username_divider.append(description_container4);
        //
        username_divider.appendSpacer(2);
        menu_divider.append(username_container);
	}
	
	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container(description_width, option_size.y);
		IMText description_label("SKILLS", small_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);

		username_divider.appendSpacer(2);
		menu_divider.append(username_container);
	}
	//
	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container(description_width, option_size.y);
		IMText description_label("Scavenging: "+params.GetInt("Search")+"%", client_connect_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);
		username_divider.appendSpacer(2);
		//
		IMContainer username_container2(option_size.x, option_size.y);
		IMDivider username_divider2("username_divider", DOHorizontal);
		IMContainer username_parent_container2(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent2("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent2);
		username_container2.setElement(username_divider2);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container2(description_width, option_size.y);
		IMText description_label2("Stealing: "+params.GetInt("Steal")+"%", client_connect_font);
		description_container2.setElement(description_label2);
		description_label2.setZOrdering(3);
		username_divider.append(description_container2);
		username_divider.appendSpacer(2);
		
		//
		IMContainer username_container3(option_size.x, option_size.y);
		IMDivider username_divider3("username_divider", DOHorizontal);
		IMContainer username_parent_container3(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent3("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent3);
		username_container3.setElement(username_divider3);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container3(description_width, option_size.y);
		IMText description_label3("Bushcraft: "+params.GetInt("Tracking")+"%", client_connect_font);
		description_container3.setElement(description_label3);
		description_label3.setZOrdering(3);
		username_divider.append(description_container3);
		username_divider.appendSpacer(2);
		IMContainer username_container4(option_size.x, option_size.y);
		IMDivider username_divider4("username_divider", DOHorizontal);
		IMContainer username_parent_container4(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent4("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent4);
		username_container4.setElement(username_divider4);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container4(description_width, option_size.y);
		IMText description_label4("Meditation: "+params.GetInt("Faith")+"%", client_connect_font);
		description_container4.setElement(description_label4);
		description_label4.setZOrdering(3);
		username_divider.append(description_container4);
		username_divider.appendSpacer(2);
		menu_divider.append(username_container);
	}
	
	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container(description_width, option_size.y);
		IMText description_label("STATUS", small_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);
		username_divider.appendSpacer(2);
		menu_divider.append(username_container);
	}
	
	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container(description_width, option_size.y);
		IMText description_label("Food: "+params.GetInt("Food")+"%", client_connect_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);
		username_divider.appendSpacer(2);
		//
		IMContainer username_container2(option_size.x, option_size.y);
		IMDivider username_divider2("username_divider", DOHorizontal);
		IMContainer username_parent_container2(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent2("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent2);
		username_container2.setElement(username_divider2);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container2(description_width, option_size.y);
		IMText description_label2("Water: "+params.GetInt("Water")+"%", client_connect_font);
		description_container2.setElement(description_label2);
		description_label2.setZOrdering(3);
		username_divider.append(description_container2);
		username_divider.appendSpacer(2);
		//
		IMContainer username_container4(option_size.x, option_size.y);
		IMDivider username_divider4("username_divider", DOHorizontal);
		IMContainer username_parent_container4(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent4("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent4);
		username_container4.setElement(username_divider4);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container4(description_width, option_size.y);
		IMText description_label4("Bless: "+params.GetInt("Bless")+"%", client_connect_font);
		description_container4.setElement(description_label4);
		description_label4.setZOrdering(3);
		username_divider.append(description_container4);
		username_divider.appendSpacer(2);
		menu_divider.append(username_container);
		//
		
	}
	
	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container(description_width, option_size.y);
		IMText description_label("AFFLICTIONS", small_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);
		username_divider.appendSpacer(2);
		menu_divider.append(username_container);
	}
	
	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container(description_width, option_size.y);
		IMText description_label("Freezing: "+(params.GetInt("Freezing")*20)+"%", client_connect_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);
		username_divider.appendSpacer(2);
		//
		IMContainer username_container2(option_size.x, option_size.y);
		IMDivider username_divider2("username_divider", DOHorizontal);
		IMContainer username_parent_container2(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent2("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent2);
		username_container2.setElement(username_divider2);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container2(description_width, option_size.y);
		IMText description_label2("Poison: "+params.GetInt("Poison")+"%", client_connect_font);
		description_container2.setElement(description_label2);
		description_label2.setZOrdering(3);
		username_divider.append(description_container2);
		username_divider.appendSpacer(2);
		
		//
		IMContainer username_container3(option_size.x, option_size.y);
		IMDivider username_divider3("username_divider", DOHorizontal);
		IMContainer username_parent_container3(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent3("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent3);
		username_container3.setElement(username_divider3);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container3(description_width, option_size.y);
		IMText description_label3("Sickness: "+params.GetInt("Sick")+"%", client_connect_font);
		description_container3.setElement(description_label3);
		description_label3.setZOrdering(3);
		username_divider.append(description_container3);
		username_divider.appendSpacer(2);
		IMContainer username_container4(option_size.x, option_size.y);
		IMDivider username_divider4("username_divider", DOHorizontal);
		IMContainer username_parent_container4(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent4("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent4);
		username_container4.setElement(username_divider4);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container4(description_width, option_size.y);
		//zzz
		IMText description_label4("Hunted: "+(params.GetInt("huntLevel")/3)+"%", client_connect_font);
		description_container4.setElement(description_label4);
		description_label4.setZOrdering(3);
		username_divider.append(description_container4);
		username_divider.appendSpacer(2);
		menu_divider.append(username_container);
	}
	
	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container(description_width, option_size.y);
		IMText description_label("MASTERY", small_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);
		username_divider.appendSpacer(2);
		menu_divider.append(username_container);
	}
	
	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container(description_width, option_size.y);
		IMText description_label("Kung Fu", client_connect_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);
		username_divider.appendSpacer(2);
		//
		IMContainer username_container2(option_size.x, option_size.y);
		IMDivider username_divider2("username_divider", DOHorizontal);
		IMContainer username_parent_container2(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent2("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent2);
		username_container2.setElement(username_divider2);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container2(description_width, option_size.y);
		IMText description_label2("Kenjutsu", client_connect_font);
		description_container2.setElement(description_label2);
		description_label2.setZOrdering(3);
		username_divider.append(description_container2);
		username_divider.appendSpacer(2);
		
		//
		IMContainer username_container3(option_size.x, option_size.y);
		IMDivider username_divider3("username_divider", DOHorizontal);
		IMContainer username_parent_container3(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent3("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent3);
		username_container3.setElement(username_divider3);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container3(description_width, option_size.y);
		IMText description_label3("Ninjitsu", client_connect_font);
		description_container3.setElement(description_label3);
		description_label3.setZOrdering(3);
		username_divider.append(description_container3);
		username_divider.appendSpacer(2);
		IMContainer username_container4(option_size.x, option_size.y);
		IMDivider username_divider4("username_divider", DOHorizontal);
		IMContainer username_parent_container4(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent4("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent4);
		username_container4.setElement(username_divider4);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container4(description_width, option_size.y);
		IMText description_label4("Shuri Jitsu", client_connect_font);
		description_container4.setElement(description_label4);
		description_label4.setZOrdering(3);
		username_divider.append(description_container4);
		username_divider.appendSpacer(2);
		menu_divider.append(username_container);
	}
	
		{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");
		IMContainer description_container(description_width, option_size.y);
		IMText description_label("TRINKET", small_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);
		username_divider.appendSpacer(2);
		menu_divider.append(username_container);
	}
	
	{
		//ImGui_BulletText("Click and drag on any empty space to move window.");
		//Username input field.
		IMContainer username_container(option_size.x, option_size.y);
		IMDivider username_divider("username_divider", DOHorizontal);
		IMContainer username_parent_container(button_size.x / 2.0f, button_size.y);
		username_parent_container.sendMouseOverToChildren(true);
		username_parent_container.sendMouseDownToChildren(true);
		IMDivider username_parent("username_parent", DOHorizontal);
		username_parent_container.setElement(username_parent);
		username_container.setElement(username_divider);
		username_parent_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_username_field"), "");

		IMContainer description_container(description_width, option_size.y);
		string trinketText = "You have no trinkets. You currently have "+(trinketChances*10)+"% chances to find a trinket Altar.";
		if (params.GetString("trinketType")== "Glacier"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" giving you a "+(params.GetInt("trinketPower")*5)+"% resist to freezing.");
		}else if(params.GetString("trinketType")== "Knowledge"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" increasing all your skills by "+(params.GetInt("trinketPower"))+"%.");
		}else if(params.GetString("trinketType")== "Venom"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" giving you a "+(params.GetInt("trinketPower")*5)+"% resist to poison.");
		}else if(params.GetString("trinketType")== "Purity"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" giving you a "+(params.GetInt("trinketPower")*5)+"% resist to disease.");
		}else if(params.GetString("trinketType")== "Fasting"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" delaying hunger by "+(params.GetInt("trinketPower")*5)+"%.");
		}else if(params.GetString("trinketType")== "Evasion"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" allowing you to escape hunters "+(params.GetInt("trinketPower")*5)+"% faster.");
		}else if(params.GetString("trinketType")== "Wendigo"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" giving you a "+(params.GetInt("trinketPower")*5)+"% to avoid the Wendigo at night.");
		}else if(params.GetString("trinketType")== "Wisdom"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" giving you a "+(params.GetInt("trinketPower")*5)+"% more scrolls in your loot.");
		}else if(params.GetString("trinketType")== "Fortune"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" giving you a "+(params.GetInt("trinketPower")*5)+"% more gold in your loot.");
		}else if(params.GetString("trinketType")== "Plenty"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" giving you a "+(params.GetInt("trinketPower")*5)+"% more food/water when eating/drinking.");
		}else if(params.GetString("trinketType")== "the Guild"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" giving you a "+(params.GetInt("trinketPower"))+"% to an item for free when trading.");
		}else if(params.GetString("trinketType")== "the Guild"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" giving you a "+(params.GetInt("trinketPower"))+"% to an item for free when trading.");
		}else if(params.GetString("trinketType")== "the Monk"){
			trinketText = (trinketPowerTell(params.GetInt("trinketPower"))+" trinket of "+params.GetString("trinketType")+" making blessings last "+(params.GetInt("trinketPower")*5)+"% longer.");
		}
		IMText description_label(trinketText, client_connect_font);
		description_container.setElement(description_label);
		description_label.setZOrdering(3);
		username_divider.append(description_container);
		username_divider.appendSpacer(2);
		//
		menu_divider.append(username_container);
	}


	menu_divider.appendSpacer(20);

	//The main background
	IMImage background(white_background);
	background.addLeftMouseClickBehavior(IMFixedMessageOnClick("close_all"), "");
	background.setColor(background_color);
	background.setSize(vec2(menu_size.x, 1000));
	menu_container.addFloatingElement(background, "background", vec2(0));
	imGUI.getMain().setSize(vec2(2560, 1000));
	imGUI.getMain().setElement(menu_container);
}
void rogueUI(string type){
	level.SendMessage("clearhud");
	Object @obj = ReadObjectFromID(player_id);
	ScriptParams@ params = obj.GetScriptParams();
		if(type == "Food"){
			if(spam <= 0){
			rogueUI_timer = 2.0f;
		
			if(params.GetInt("Food") > 75){
				level.SendMessage("displayhud /Data/UI/Icons/foodFull.png");
			}else if(params.GetInt("Food") > 50){
				level.SendMessage("displayhud /Data/UI/Icons/food60.png");
			}else if(params.GetInt("Food") > 25){
				level.SendMessage("displayhud /Data/UI/Icons/food30.png");
			}else{
				level.SendMessage("displayhud /Data/UI/Icons/food0.png");
			}
			}else{
			spam --;
			}
		}else if(type == "Water"){
			if(spam <= 0){
				rogueUI_timer = 2.0f;
		
				if(params.GetInt("Water") > 75){
					level.SendMessage("displayhud /Data/UI/Icons/waterFull.png");
				}else if(params.GetInt("Water") > 50){
					level.SendMessage("displayhud /Data/UI/Icons/water60.png");
				}else if(params.GetInt("Water") > 25){
					level.SendMessage("displayhud /Data/UI/Icons/water30.png");
				}else{
					level.SendMessage("displayhud /Data/UI/Icons/water0.png");
				}
			}else{
				spam --;
			}
	}else if(type == "Ill"){
		rogueUI_timer = 2.0f;
		
		if(params.GetInt("Sick") > 0){
			level.SendMessage("displayhud /Data/UI/Icons/Ill.png");
		}else {
			level.SendMessage("displayhud /Data/UI/Icons/notIll.png");
		}
	}else if(type == "Blessed"){
		rogueUI_timer = 2.0f;
		
		if(params.GetInt("Bless") > 0){
			level.SendMessage("displayhud /Data/UI/Icons/blessed.png");
		}else {
			level.SendMessage("displayhud /Data/UI/Icons/notBlessed.png");
		}
	}else if(type == "Scroll"){
		rogueUI_timer = 2.0f;
		level.SendMessage("displayhud /Data/UI/Icons/scroll"+params.GetInt("xp")+".png");
	}else if(type == "Scroll"){
        rogueUI_timer = 2.0f;
        level.SendMessage("displayhud /Data/UI/Icons/mapHUD.png");
    }else if(type == "lockPick"){
		rogueUI_timer = 2.0f;
		level.SendMessage("displayhud /Data/UI/Icons/lockPick"+params.GetInt("lockPick")+".png");
	}else if(type == "Gold"){
		rogueUI_timer = 2.0f;
		level.SendMessage("displaytext \""+"You now have "+params.GetInt("Gold")+" gold pieces"+"\"");
		if(params.GetInt("Gold") >= 45){
			level.SendMessage("displayhud /Data/UI/Icons/gold10.png");
		}else if(params.GetInt("Gold") >= 40){
			level.SendMessage("displayhud /Data/UI/Icons/gold9.png");
		}else if(params.GetInt("Gold") >= 35){
			level.SendMessage("displayhud /Data/UI/Icons/gold8.png");
		}else if(params.GetInt("Gold") >= 30){
			level.SendMessage("displayhud /Data/UI/Icons/gold7.png");
		}else if(params.GetInt("Gold") >= 25){
			level.SendMessage("displayhud /Data/UI/Icons/gold6.png");
		}else if(params.GetInt("Gold") >= 20){
			level.SendMessage("displayhud /Data/UI/Icons/gold5.png");
		}else if(params.GetInt("Gold") >= 15){
			level.SendMessage("displayhud /Data/UI/Icons/gold4.png");
		}else if(params.GetInt("Gold") >= 10){
			level.SendMessage("displayhud /Data/UI/Icons/gold3.png");
		}else if(params.GetInt("Gold") >= 5){
			level.SendMessage("displayhud /Data/UI/Icons/gold2.png");
		}else if(params.GetInt("Gold") > 0){
			level.SendMessage("displayhud /Data/UI/Icons/gold1.png");
		}
	}else if(type == "noLoot"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/noLoot.png");
	}else if(type == "noPray"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/noPray.png");
	}else if(type == "noSteal"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/noSteal.png");
	}else if(type == "stealage"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/stealage.png");
	}else if(type == "lootage"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/lootage.png");
		//fireNear
	}else if(type == "FireNear"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/FireNear.png");
		//fireNear
	}else if(type == "FireFar"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/FireFar.png");
		//fireNear
	}else if(type == "prayage"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/prayage.png");
	}else if(type == "Gear"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/geared.png");
	}else if(type == "notBlessed"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/notBlessed.png");
	}else if(type == "Snowing"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/snowing.png");
	}else if(type == "Sunny"){
		rogueUI_timer = 2.0f;
		
		level.SendMessage("displayhud /Data/UI/Icons/sunny.png");
	}else if(type == "cue1"){
		rogueUI_timer = 6.0f;
		level.SendMessage("displayhud /Data/UI/Icons/cue1.png");
	}else if(type == "cue2"){
		rogueUI_timer = 6.0f;
		level.SendMessage("displayhud /Data/UI/Icons/cue2.png");
	}else if(type == "cue3"){
		rogueUI_timer = 6.0f;
		level.SendMessage("displayhud /Data/UI/Icons/cue3.png");
	}else if(type == "tipDelay"){
		rogueUI_timer = 10.0f;
		
	}else if(type == "Freezing"){
		rogueUI_timer = 4.0f;
		
		if(params.GetInt("Freezing") >= 3){
			level.SendMessage("displayhud /Data/UI/Icons/freezing3.png");
		}else if(params.GetInt("Freezing") == 2){
			level.SendMessage("displayhud /Data/UI/Icons/freezing2.png");
		}else if(params.GetInt("Freezing") == 1){
			level.SendMessage("displayhud /Data/UI/Icons/freezing1.png");
		}else if(params.GetInt("Freezing") == 0){
			level.SendMessage("displayhud /Data/UI/Icons/freezing0.png");
		}
	}else if(type == "Warming"){
		rogueUI_timer = 4.0f;
		if(params.GetInt("Freezing") >= 2){
			level.SendMessage("displayhud /Data/UI/Icons/warming2.png");
		}else if(params.GetInt("Freezing") == 1){
			level.SendMessage("displayhud /Data/UI/Icons/warming1.png");
		}else if(params.GetInt("Freezing") == 0){
			level.SendMessage("displayhud /Data/UI/Icons/warming0.png");
		}
	}else if(type == "questReceived"){
			rogueUI_timer = 8.0f;
			level.SendMessage("displayhud /Data/UI/Icons/quest"+params.GetInt("questType")+".png");
	}
	spam = 3;
}
