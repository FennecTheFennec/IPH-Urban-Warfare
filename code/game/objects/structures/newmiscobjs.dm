/obj/structure/body1
	name = "rotting body"
	desc = "Rotting and festering. Seems like it was here for a while."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "dead1"
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER
	density = 0
	opacity = 1
	w_class = ITEM_SIZE_NORMAL

/obj/structure/body1/New()
	..()

/obj/structure/body1/attackby(obj/item/I, mob/user)
	to_chat(user, "<span class='warning'>\The [src] doesn't seem to be very alive!</span>")
	return

/obj/structure/body2
	name = "rotting body"
	desc = "Rotting and festering. Seems like it was here for a while."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "dead2"
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER
	density = 0
	opacity = 1
	w_class = ITEM_SIZE_NORMAL

/obj/structure/body2/New()
	..()

/obj/structure/body2/attackby(obj/item/I, mob/user)
	to_chat(user, "<span class='warning'>\The [src] doesn't seem to be very alive!</span>")
	return

/obj/structure/body3
	name = "rotting body on a spike"
	desc = "Rotting and festering. Seems like it was here for a while. Is impaled on a spike."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "dead3"
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER
	density = 0
	opacity = 1
	w_class = ITEM_SIZE_NORMAL

/obj/structure/body3/New()
	..()

/obj/structure/body3/attackby(obj/item/I, mob/user)
	to_chat(user, "<span class='warning'>\The [src] doesn't seem to be very alive!</span>")
	return

/obj/structure/woodentv
	name = "wooden tv"
	desc = "An old, wooden TV. Doesn't seem to show anything of value."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "wooden_tv_unpowered"
	plane = OBJ_PLANE
	layer = ABOVE_WINDOW_LAYER
	opacity = 1
	density = 1

/obj/structure/woodentv/on
	icon_state = "wooden_tv"
	plane = ABOVE_HUMAN_PLANE
	layer = ABOVE_HUMAN_LAYER

/obj/structure/woodentv/attack_hand(mob/user)
	playsound(get_turf(loc), "button2", 15, 1, -5)
	toggle()
	..()

/obj/structure/woodentv/proc/toggle()
	if(toggle())
		icon_state = "wooden_tv"
		plane = ABOVE_HUMAN_PLANE
		layer = ABOVE_WINDOW_LAYER
	else
		icon_state = "wooden_tv_unpowered"
		plane = OBJ_PLANE
		layer = ABOVE_WINDOW_LAYER

/obj/structure/microscope
	name = "microscope"
	desc = "A microscope. It's broken."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "microscope1"
	plane = OBJ_PLANE
	layer = ABOVE_WINDOW_LAYER
	opacity = 1
	density = 1

/obj/structure/fishwall
	name = "a fish trophy"
	desc = "A fish trophy on the wall. Doesn't seem to play anything anymore...unless?"
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "fish"
	pixel_y = 32
	plane = OBJ_PLANE
	layer = ABOVE_WINDOW_LAYER
	opacity = 1
	density = 0

/obj/structure/hospitaltech1
	name = "some hospital device"
	desc = "A weird hospital device. Doesn't do anything."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "a3"
	plane = OBJ_PLANE
	layer = ABOVE_WINDOW_LAYER
	opacity = 1
	density = 1

/obj/structure/hospitaltech2
	name = "some hospital device"
	desc = "A weird hospital device. Doesn't do anything."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "a5"
	plane = OBJ_PLANE
	layer = ABOVE_WINDOW_LAYER
	opacity = 1
	density = 1

/obj/structure/hospitaltech3
	name = "some hospital device"
	desc = "A weird hospital device. Doesn't do anything."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "a9"
	plane = OBJ_PLANE
	layer = ABOVE_WINDOW_LAYER
	opacity = 1
	density = 1

/obj/structure/hospitaltech4
	name = "some hospital device"
	desc = "A weird hospital device. Doesn't do anything."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "a10"
	plane = OBJ_PLANE
	layer = ABOVE_WINDOW_LAYER
	opacity = 1
	density = 1

/obj/structure/hospitaltech5
	name = "some hospital device"
	desc = "A weird hospital device. Doesn't do anything."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "a11"
	plane = OBJ_PLANE
	layer = ABOVE_WINDOW_LAYER
	opacity = 1
	density = 1

/obj/structure/hospitaltech6
	name = "some hospital device"
	desc = "A weird hospital device. Doesn't do anything except...work on something."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "a13"
	plane = OBJ_PLANE
	layer = ABOVE_WINDOW_LAYER
	opacity = 1
	density = 1

/obj/structure/woodenclock
	name = "some hospital device"
	desc = "An old, wooden clock. Tick tack."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "pclock"
	plane = OBJ_PLANE
	layer = ABOVE_WINDOW_LAYER
	opacity = 1
	density = 1

/obj/structure/woodenclock/New()
	ticktock()
	..()

/obj/structure/woodenclock/proc/ticktock()
	playsound(get_turf(src), "clock_ticking", 35, 1, -5)

/obj/structure/nuclearwaste
	name = "big nuclear waste canister"
	desc = "A big nuclear waste canister. Better stay away from this..."
	icon = 'icons/obj/miscobjs.dmi'
	icon_state = "a8"
	plane = OBJ_PLANE
	layer = ABOVE_WINDOW_LAYER
	opacity = 1
	density = 1
	var/radioactivity = 1

/obj/structure/nuclearwaste/New()
	..()
	if(istype(loc, /turf))
		radiation_repository.radiate(src, max(1,ceil(radioactivity/30))) //I'm not sure how OP this is...