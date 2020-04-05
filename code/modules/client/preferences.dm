#define SAVE_RESET -1

datum/preferences
	//doohickeys for savefiles
	var/path
	var/default_slot = 1				//Holder so it doesn't default to slot 1, rather the last one used
	var/savefile_version = 0

	//non-preference stuff
	var/warns = 0
	var/muted = 0
	var/last_ip
	var/last_id

	//game-preferences
	var/lastchangelog = ""				//Saved changlog filesize to detect if there was a change

	//character preferences
	var/species_preview                 //Used for the species selection window.

		//Mob preview
	var/icon/preview_icon = null

	var/client/client = null
	var/hotkeys = TRUE
	var/client_ckey = null

	var/savefile/loaded_preferences
	var/savefile/loaded_character
	var/datum/category_collection/player_setup_collection/player_setup
	var/datum/browser/panel

	// Custom Keybindings
	var/list/key_bindings = null

/datum/preferences/New(client/C)
	if(istype(C))
		client = C
		client_ckey = C.ckey
		SScharacter_setup.preferences_datums += src
		if(SScharacter_setup.initialized)
			setup()
		else
			SScharacter_setup.prefs_awaiting_setup += src
	..()

/datum/preferences/proc/setup()
	player_setup = new(src)
	gender = pick(MALE, FEMALE)
	real_name = random_name(gender,species)
	b_type = RANDOM_BLOOD_TYPE

	if(client && !IsGuestKey(client.key))
		load_path(client.ckey)
		load_preferences()
		key_bindings = deepCopyList(GLOB.hotkey_keybinding_list_by_key) // give them default keybinds and update their movement keys
		load_and_update_character()
	sanitize_preferences()

/datum/preferences/proc/load_and_update_character(var/slot)
	load_character(slot)
	if(update_setup(loaded_preferences, loaded_character))
		SScharacter_setup.queue_preferences_save(src)
		save_character()

/datum/preferences/proc/keybindings_setup(client/C)
	var/choice = tgalert(C, "Would you prefer 'Hotkey' or 'Classic' defaults?", "Setup keybindings", "Hotkey", "Classic")
	hotkeys = (choice == "Classic")
	key_bindings = (!hotkeys) ? deepCopyList(GLOB.hotkey_keybinding_list_by_key) : deepCopyList(GLOB.classic_keybinding_list_by_key)
	save_preferences()

/datum/preferences/proc/ShowKeybindings(mob/user)
	// Create an inverted list of keybindings -> key
	var/list/user_binds = list()
	for(var/key in key_bindings)
		for(var/kb_name in key_bindings[key])
			user_binds[kb_name] += list(key)

	var/list/kb_categories = list()
	// Group keybinds by category
	for(var/name in GLOB.keybindings_by_name)
		var/datum/keybinding/kb = GLOB.keybindings_by_name[name]
		kb_categories[kb.category] += list(kb)

	var/HTML = "<style>label { display: inline-block; width: 200px; }</style><body>"
	HTML += "<br>"
	HTML += "<a href ='?_src_=prefs;preference=keybindings_done'>Close</a>"
	HTML += "<a href ='?_src_=prefs;preference=keybindings_reset'>Reset to default</a>"
	HTML += "<br><br>"
	for(var/category in kb_categories)
		HTML += "<h3>[category]</h3>"
		for(var/i in kb_categories[category])
			var/datum/keybinding/kb = i
			if(!length(user_binds[kb.name]))
				HTML += "<label>[kb.full_name]</label> <a href ='?_src_=prefs;preference=keybindings_capture;keybinding=[kb.name];old_key=["Unbound"]'>Unbound</a>"
				var/list/default_keys = hotkeys ? kb.hotkey_keys : kb.classic_keys
				if(LAZYLEN(default_keys))
					HTML += "| Default: [default_keys.Join(", ")]"
				HTML += "<br>"
			else
				var/bound_key = user_binds[kb.name][1]
				HTML += "<label>[kb.full_name]</label> <a href ='?_src_=prefs;preference=keybindings_capture;keybinding=[kb.name];old_key=[bound_key]'>[bound_key]</a>"
				for(var/bound_key_index in 2 to length(user_binds[kb.name]))
					bound_key = user_binds[kb.name][bound_key_index]
					HTML += " | <a href ='?_src_=prefs;preference=keybindings_capture;keybinding=[kb.name];old_key=[bound_key]'>[bound_key]</a>"
				if(length(user_binds[kb.name]) < MAX_KEYS_PER_KEYBIND)
					HTML += "| <a href ='?_src_=prefs;preference=keybindings_capture;keybinding=[kb.name]'>Add Secondary</a>"
				var/list/default_keys = hotkeys ? kb.hotkey_keys : kb.classic_keys
				if(LAZYLEN(default_keys))
					HTML += "| Default: [default_keys.Join(", ")]"
				HTML += "<br>"

	HTML += "<br><br>"
	HTML += "<a href ='?_src_=prefs;preference=keybindings_done'>Close</a>"
	HTML += "<a href ='?_src_=prefs;preference=keybindings_reset'>Reset to default</a>"
	HTML += "</body>"

	winshow(user, "keybindings", TRUE)
	var/datum/browser/popup = new(user, "keybindings", "<div align='center'>Keybindings</div>", 500, 900)
	popup.set_content(HTML)
	popup.open(FALSE)
	onclose(user, "keybindings", src)

/datum/preferences/proc/CaptureKeybinding(mob/user, datum/keybinding/kb, old_key)
	var/HTML = {"
	<div id='focus' style="outline: 0;" tabindex=0>Keybinding: [kb.full_name]<br>[kb.description]<br><br><b>Press any key to change<br>Press ESC to clear</b></div>
	<script>
	var deedDone = false;
	document.onkeyup = function(e) {
		if(deedDone){ return; }
		var alt = e.altKey ? 1 : 0;
		var ctrl = e.ctrlKey ? 1 : 0;
		var shift = e.shiftKey ? 1 : 0;
		var numpad = (95 < e.keyCode && e.keyCode < 112) ? 1 : 0;
		var escPressed = e.keyCode == 27 ? 1 : 0;
		var url = 'byond://?_src_=prefs;preference=keybindings_set;keybinding=[kb.name];old_key=[old_key];clear_key='+escPressed+';key='+e.key+';alt='+alt+';ctrl='+ctrl+';shift='+shift+';numpad='+numpad+';key_code='+e.keyCode;
		window.location=url;
		deedDone = true;
	}
	document.getElementById('focus').focus();
	</script>
	"}
	winshow(user, "capturekeypress", TRUE)
	var/datum/browser/popup = new(user, "capturekeypress", "<div align='center'>Keybindings</div>", 350, 300)
	popup.set_content(HTML)
	popup.open(FALSE)
	onclose(user, "capturekeypress", src)

/datum/preferences/proc/ShowChoices(mob/user)
	if(!SScharacter_setup.initialized)
		return
	if(!user || !user.client)
		return

	if(!get_mob_by_key(client_ckey))
		to_chat(user, "<span class='danger'>No mob exists for the given client!</span>")
		close_load_dialog(user)
		return

	var/dat = "<html><body><center>"

	if(path)
		dat += "Slot - "
		dat += "<a href='?src=\ref[src];load=1'>Load slot</a> - "
		dat += "<a href='?src=\ref[src];save=1'>Save slot</a> - "
		dat += "<a href='?src=\ref[src];resetslot=1'>Reset slot</a> - "
		dat += "<a href='?src=\ref[src];reload=1'>Reload slot</a> - "
		dat += "<a href='?_src_=prefs;preference=keybindings_menu'>Keybindings</a>"

	else
		dat += "Please create an account to save your preferences."

	dat += "<br>"
	dat += player_setup.header()
	dat += "<br><HR></center>"
	dat += player_setup.content(user)

	dat += "</html></body>"
	var/datum/browser/popup = new(user, "Character Setup","Character Setup", 1200, 800, src)
	popup.set_content(dat)
	popup.open()

/datum/preferences/Topic(href, list/href_list)
	if(..())
		return 1

	if(href_list["save"])
		save_preferences()
		save_character()
	else if(href_list["reload"])
		load_preferences()
		load_character()
		sanitize_preferences()
	else if(href_list["load"])
		if(!IsGuestKey(usr.key))
			open_load_dialog(usr)
			return 1
	else if(href_list["changeslot"])
		load_character(text2num(href_list["changeslot"]))
		sanitize_preferences()
		close_load_dialog(usr)
	else if(href_list["resetslot"])
		if(real_name != input("This will reset the current slot. Enter the character's full name to confirm."))
			return 0
		load_character(SAVE_RESET)
		sanitize_preferences()
	else
		return 0

	ShowChoices(usr)
	return 1


/datum/preferences/proc/process_link(mob/user, list/href_list)
	if(!istype(user) || !length(href_list))
		return

	switch(href_list["preference"])
		if("keybindings_menu")
			ShowKeybindings(user)
			return

		if("keybindings_capture")
			var/datum/keybinding/kb = GLOB.keybindings_by_name[href_list["keybinding"]]
			var/old_key = href_list["old_key"]
			CaptureKeybinding(user, kb, old_key)
			return

		if("keybindings_set")
			var/kb_name = href_list["keybinding"]
			if(!kb_name)
				user << browse(null, "window=capturekeypress")
				ShowKeybindings(user)
				return

			var/clear_key = text2num(href_list["clear_key"])
			var/old_key = href_list["old_key"]
			if(clear_key)
				if(key_bindings[old_key])
					key_bindings[old_key] -= kb_name
					if(!length(key_bindings[old_key]))
						key_bindings -= old_key
				user << browse(null, "window=capturekeypress")
				save_preferences()
				ShowKeybindings(user)
				return

			var/new_key = uppertext(href_list["key"])
			var/AltMod = text2num(href_list["alt"]) ? "Alt" : ""
			var/CtrlMod = text2num(href_list["ctrl"]) ? "Ctrl" : ""
			var/ShiftMod = text2num(href_list["shift"]) ? "Shift" : ""
			var/numpad = text2num(href_list["numpad"]) ? "Numpad" : ""
			// var/key_code = text2num(href_list["key_code"])

			if(GLOB._kbMap[new_key])
				new_key = GLOB._kbMap[new_key]

			var/full_key
			switch(new_key)
				if("Alt")
					full_key = "[new_key][CtrlMod][ShiftMod]"
				if("Ctrl")
					full_key = "[AltMod][new_key][ShiftMod]"
				if("Shift")
					full_key = "[AltMod][CtrlMod][new_key]"
				else
					full_key = "[AltMod][CtrlMod][ShiftMod][numpad][new_key]"
			if(key_bindings[old_key])
				key_bindings[old_key] -= kb_name
				if(!length(key_bindings[old_key]))
					key_bindings -= old_key
			key_bindings[full_key] += list(kb_name)
			key_bindings[full_key] = sortList(key_bindings[full_key])

			user << browse(null, "window=capturekeypress")
			user.client.update_movement_keys()
			save_preferences()
			ShowKeybindings(user)
			return

		if("keybindings_done")
			user << browse(null, "window=keybindings")

		if("keybindings_reset")
			var/choice = tgalert(usr, "Would you prefer 'hotkey' or 'classic' defaults?", "Setup keybindings", "Hotkey", "Classic", "Cancel")
			if (choice == "Cancel")
				ShowKeybindings(user)
				return
			hotkeys = (choice == "Classic")
			key_bindings = (!hotkeys) ? deepCopyList(GLOB.hotkey_keybinding_list_by_key) : deepCopyList(GLOB.classic_keybinding_list_by_key)
			user.client.update_movement_keys()
			save_preferences()
			ShowKeybindings(user)
			return

		if("open_whitelist_forum")
			if(config.forumurl)
				user << link(config.forumurl)
			else
				to_chat(user, "<span class='danger'>The forum URL is not set in the server configuration.</span>")
				return

	if("hotkeys")
		hotkeys = !hotkeys
	if(hotkeys)
		winset(user, null, "input.focus=true")
	else
		winset(user, null, "mapwindow.map.focus=true")

	..()

/datum/preferences/proc/copy_to(mob/living/carbon/human/character, is_preview_copy = FALSE)
	// Sanitizing rather than saving as someone might still be editing when copy_to occurs.
	player_setup.sanitize_setup()
	character.set_species(species)
	if(be_random_name)
		real_name = random_name(gender,species)

	if(config.humans_need_surnames)
		var/firstspace = findtext(real_name, " ")
		var/name_length = length(real_name)
		if(!firstspace)	//we need a surname
			real_name += " [pick(GLOB.last_names)]"
		else if(firstspace == name_length)
			real_name += "[pick(GLOB.last_names)]"

	character.fully_replace_character_name(real_name)

	character.gender = gender
	character.age = age
	character.b_type = b_type

	character.r_eyes = r_eyes
	character.g_eyes = g_eyes
	character.b_eyes = b_eyes

	character.h_style = h_style
	character.r_hair = r_hair
	character.g_hair = g_hair
	character.b_hair = b_hair

	character.f_style = f_style
	character.r_facial = r_facial
	character.g_facial = g_facial
	character.b_facial = b_facial

	character.r_skin = r_skin
	character.g_skin = g_skin
	character.b_skin = b_skin

	character.s_tone = s_tone
	character.s_base = s_base

	character.h_style = h_style
	character.f_style = f_style

	// Replace any missing limbs.
	for(var/name in BP_ALL_LIMBS)
		var/obj/item/organ/external/O = character.organs_by_name[name]
		if(!O && organ_data[name] != "amputated")
			var/list/organ_data = character.species.has_limbs[name]
			if(!islist(organ_data)) continue
			var/limb_path = organ_data["path"]
			O = new limb_path(character)

	// Destroy/cyborgize organs and limbs. The order is important for preserving low-level choices for robolimb sprites being overridden.
	for(var/name in BP_BY_DEPTH)
		var/status = organ_data[name]
		var/obj/item/organ/external/O = character.organs_by_name[name]
		if(!O)
			continue
		O.status = 0
		O.robotic = 0
		O.model = null
		if(status == "amputated")
			character.organs_by_name[O.organ_tag] = null
			character.organs -= O
			if(O.children) // This might need to become recursive.
				for(var/obj/item/organ/external/child in O.children)
					character.organs_by_name[child.organ_tag] = null
					character.organs -= child
		else if(status == "cyborg")
			if(rlimb_data[name])
				O.robotize(rlimb_data[name])
			else
				O.robotize()
		else //normal organ
			O.force_icon = null
			O.SetName(initial(O.name))
			O.desc = initial(O.desc)
	//For species that don't care about your silly prefs
	character.species.handle_limbs_setup(character)
	if(!is_preview_copy)
		for(var/name in list(BP_HEART,BP_EYES,BP_BRAIN,BP_LUNGS,BP_LIVER,BP_KIDNEYS))
			var/status = organ_data[name]
			if(!status)
				continue
			var/obj/item/organ/I = character.internal_organs_by_name[name]
			if(I)
				if(status == "assisted")
					I.mechassist()
				else if(status == "mechanical")
					I.robotize()

	QDEL_NULL_LIST(character.worn_underwear)
	character.worn_underwear = list()

	for(var/underwear_category_name in all_underwear)
		var/datum/category_group/underwear/underwear_category = GLOB.underwear.categories_by_name[underwear_category_name]
		if(underwear_category)
			var/underwear_item_name = all_underwear[underwear_category_name]
			var/datum/category_item/underwear/UWD = underwear_category.items_by_name[underwear_item_name]
			var/metadata = all_underwear_metadata[underwear_category_name]
			var/obj/item/underwear/UW = UWD.create_underwear(metadata)
			if(UW)
				UW.ForceEquipUnderwear(character, FALSE)
		else
			all_underwear -= underwear_category_name

	character.backpack_setup = new(backpack, backpack_metadata["[backpack]"])

	for(var/N in character.organs_by_name)
		var/obj/item/organ/external/O = character.organs_by_name[N]
		O.markings.Cut()

	for(var/M in body_markings)
		var/datum/sprite_accessory/marking/mark_datum = GLOB.body_marking_styles_list[M]
		var/mark_color = "[body_markings[M]]"

		for(var/BP in mark_datum.body_parts)
			var/obj/item/organ/external/O = character.organs_by_name[BP]
			if(O)
				O.markings[M] = list("color" = mark_color, "datum" = mark_datum)

	character.force_update_limbs()
	character.update_mutations(0)
	character.update_body(0)
	character.update_underwear(0)
	character.update_hair(0)
	character.update_icons()

	character.char_branch = mil_branches.get_branch(char_branch)
	character.char_rank = mil_branches.get_rank(char_branch, char_rank)

	if(is_preview_copy)
		return

	character.flavor_texts["general"] = flavor_texts["general"]
	character.flavor_texts["head"] = flavor_texts["head"]
	character.flavor_texts["face"] = flavor_texts["face"]
	character.flavor_texts["eyes"] = flavor_texts["eyes"]
	character.flavor_texts["torso"] = flavor_texts["torso"]
	character.flavor_texts["arms"] = flavor_texts["arms"]
	character.flavor_texts["hands"] = flavor_texts["hands"]
	character.flavor_texts["legs"] = flavor_texts["legs"]
	character.flavor_texts["feet"] = flavor_texts["feet"]

	character.med_record = med_record
	character.sec_record = sec_record
	character.gen_record = gen_record
	character.exploit_record = exploit_record

	//character.home_system = home_system
	character.citizenship = citizenship
	character.personal_faction = faction
	//character.religion = religion

	if(!character.isSynthetic())
		character.nutrition = rand(140,360)

	return

/datum/preferences/proc/open_load_dialog(mob/user)
	var/dat  = list()
	dat += "<body>"
	dat += "<tt><center>"

	var/savefile/S = new /savefile(path)
	if(S)
		dat += "<b>Select a character slot to load</b><hr>"
		var/name
		for(var/i=1, i<= config.character_slots, i++)
			S.cd = GLOB.using_map.character_load_path(S, i)
			S["real_name"] >> name
			if(!name)	name = "Character[i]"
			if(i==default_slot)
				name = "<b>[name]</b>"
			dat += "<a href='?src=\ref[src];changeslot=[i]'>[name]</a><br>"

	dat += "<hr>"
	dat += "</center></tt>"
	panel = new(user, "Character Slots", "Character Slots", 300, 390, src)
	panel.set_content(jointext(dat,null))
	panel.open()

/datum/preferences/proc/close_load_dialog(mob/user)
	user << browse(null, "window=saves")
	panel.close()
