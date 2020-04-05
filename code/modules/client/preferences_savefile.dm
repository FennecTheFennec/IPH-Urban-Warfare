#define SAVEFILE_VERSION_MIN	8
#define SAVEFILE_VERSION_MAX	35

/datum/preferences/proc/load_path(ckey,filename="preferences.sav")
	if(!ckey)	return
	path = "data/player_saves/[copytext(ckey,1,2)]/[ckey]/[filename]"
	savefile_version = SAVEFILE_VERSION_MAX

/datum/preferences/proc/load_preferences()
	if(!path)				return 0
	if(!fexists(path))		return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = "/"

	S["version"] >> savefile_version
	player_setup.load_preferences(S)
	loaded_preferences = S
	return 1


	if(savefile_version < 35)
		WRITE_FILE(S["hotkeys"], FALSE)

	if(savefile_version < 34)
		READ_FILE(S["key_bindings"], key_bindings)
		if(key_bindings)
			key_bindings = sanitize_islist(key_bindings, list())
			key_bindings["T"] = list(1 = "say")
			key_bindings["M"] = list(1 = "me")
			key_bindings["O"] = list(1 = "ooc")
			key_bindings["L"] = list(1 = "looc")
			WRITE_FILE(S["key_bindings"], key_bindings)

	if(savefile_version < 33)
		if(!length(S["key_bindings"]))
			WRITE_FILE(S["key_bindings"], deepCopyList(GLOB.hotkey_keybinding_list_by_key))

	if(savefile_version < 31)
		WRITE_FILE(S["key_bindings"], null)

	if(savefile_version < 30)
		WRITE_FILE(S["key_bindings"], null)

	if(savefile_version < 26)
		WRITE_FILE(S["key_bindings"], null)

	if(savefile_version < 23)
		WRITE_FILE(S["hotkeys"], TRUE)

/datum/preferences/proc/save_preferences()
	if(!path)				return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = "/"

	S["version"] << SAVEFILE_VERSION_MAX
	SScharacter_setup.queue_preferences_save(S)
	loaded_preferences = S
	return 1

/datum/preferences/proc/load_character(slot)
	if(!path)				return 0
	if(!fexists(path))		return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = "/"
	if(!slot)	slot = default_slot

	if(slot != SAVE_RESET) // SAVE_RESET will reset the slot as though it does not exist, but keep the current slot for saving purposes.
		slot = sanitize_integer(slot, 1, config.character_slots, initial(default_slot))
		if(slot != default_slot)
			default_slot = slot
			S["default_slot"] << slot
	else
		S["default_slot"] << default_slot

	if(slot != SAVE_RESET)
		S.cd = GLOB.using_map.character_load_path(S, slot)
		player_setup.load_character(S)
	else
		player_setup.load_character(S)
		S.cd = GLOB.using_map.character_load_path(S, default_slot)

	READ_FILE(S["hotkeys"], hotkeys)
	READ_FILE(S["key_bindings"], key_bindings)

	loaded_character = S

	return 1

/datum/preferences/proc/save_character()
	if(!path)				return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = GLOB.using_map.character_save_path(default_slot)

	S["version"] << SAVEFILE_VERSION_MAX
	player_setup.save_character(S)
	loaded_character = S
	return S

/datum/preferences/proc/sanitize_preferences()
	player_setup.sanitize_setup()

	hotkeys			= sanitize_integer(hotkeys, FALSE, TRUE, initial(hotkeys))

	key_bindings 	= sanitize_islist(key_bindings, list())

	return 1

/datum/preferences/proc/update_setup(var/savefile/preferences, var/savefile/character)
	if(!preferences || !character)
		return 0
	return player_setup.update_setup(preferences, character)

#undef SAVEFILE_VERSION_MAX
#undef SAVEFILE_VERSION_MIN