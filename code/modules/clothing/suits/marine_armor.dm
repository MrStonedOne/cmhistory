
#define DEBUG_ARMOR_PROTECTION 0

#if DEBUG_ARMOR_PROTECTION
/mob/living/carbon/human/verb/check_overall_protection()
	set name = "Get Armor Value"
	set category = "Debug"
	set desc = "Shows the armor value of the bullet category."

	var/armor = 0
	var/counter = 0
	for(var/i in organs_by_name)
		armor = getarmor_organ(organs_by_name[i], "bullet")
		src << "<span class='debuginfo'><b>[i]</b> is protected with <b>[armor]</b> armor against bullets.</span>"
		counter += armor
	src << "<span class='debuginfo'>The overall armor score is: <b>[counter]</b>.</span>"
#endif

//=======================================================================\\
//=======================================================================\\

#define ALPHA		1
#define BRAVO		2
#define CHARLIE		3
#define DELTA		4
#define NONE 		5

var/list/armormarkings = list()
var/list/armormarkings_sql = list()
var/list/helmetmarkings = list()
var/list/helmetmarkings_sql = list()
var/list/squad_colors = list(rgb(230,25,25), rgb(255,195,45), rgb(160,32,240), rgb(65,72,200))

/proc/initialize_marine_armor()
	var/i
	for(i=1, i<5, i++)
		var/image/armor
		var/image/helmet
		armor = image('icons/Marine/marine_armor.dmi',icon_state = "std-armor")
		armor.color = squad_colors[i]
		armormarkings += armor
		armor = image('icons/Marine/marine_armor.dmi',icon_state = "sql-armor")
		armor.color = squad_colors[i]
		armormarkings_sql += armor

		helmet = image('icons/Marine/marine_armor.dmi',icon_state = "std-helmet")
		helmet.color = squad_colors[i]
		helmetmarkings += helmet
		helmet = image('icons/Marine/marine_armor.dmi',icon_state = "sql-helmet")
		helmet.color = squad_colors[i]
		helmetmarkings_sql += helmet




// MARINE STORAGE ARMOR

/obj/item/clothing/suit/storage/marine
	name = "\improper M3 pattern marine armor"
	desc = "A standard Colonial Marines M3 Pattern Chestplate. Protects the chest from ballistic rounds, bladed objects and accidents. It has a small leather pouch strapped to it for limited storage."
	icon = 'icons/Marine/marine_armor.dmi'
	icon_state = "1"
	item_state = "armor"
	icon_override = 'icons/Marine/marine_armor.dmi'
	flags_atom = FPRINT|CONDUCT
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS
	flags_cold_protection = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS
	flags_heat_protection = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS
	min_cold_protection_temperature = ARMOR_min_cold_protection_temperature
	max_heat_protection_temperature = ARMOR_max_heat_protection_temperature
	blood_overlay_type = "armor"
	armor = list(melee = 50, bullet = 40, laser = 35, energy = 20, bomb = 25, bio = 0, rad = 0)
	siemens_coefficient = 0.7
	slowdown = SLOWDOWN_ARMOR_MEDIUM
	allowed = list(/obj/item/weapon/gun/,
		/obj/item/weapon/tank/emergency_oxygen,
		/obj/item/device/flashlight,
		/obj/item/ammo_magazine/,
		/obj/item/weapon/storage/fancy/cigarettes,
		/obj/item/weapon/flame/lighter,
		/obj/item/weapon/grenade,
		/obj/item/weapon/storage/bible,
		///obj/item/weapon/claymore/mercsword/machete,
		/obj/item/weapon/flamethrower,
		/obj/item/device/binoculars,
		/obj/item/weapon/combat_knife,
		/obj/item/weapon/storage/sparepouch,
		/obj/item/weapon/storage/large_holster/machete,
		/obj/item/weapon/storage/belt/gun/m4a3,
		/obj/item/weapon/storage/belt/gun/m44)

	var/brightness_on = 5 //Average attachable pocket light
	var/flashlight_cooldown = 0 //Cooldown for toggling the light
	var/locate_cooldown = 0 //Cooldown for SL locator
	var/armor_overlays[]
	actions_types = list(/datum/action/item_action/toggle)
	var/flags_marine_armor = ARMOR_SQUAD_OVERLAY|ARMOR_LAMP_OVERLAY
	w_class = 5
	uniform_restricted = list(/obj/item/clothing/under/marine)

	New(loc,expected_type 		= /obj/item/clothing/suit/storage/marine,
		new_name[] 			= list(/datum/game_mode/ice_colony = "\improper M3 pattern marine snow armor"))
		if(type == /obj/item/clothing/suit/storage/marine)
			var/armor_variation = rand(1,6)
			switch(armor_variation)
				if(2,3)
					flags_armor_protection = UPPER_TORSO|LOWER_TORSO|LEGS
					flags_cold_protection = flags_armor_protection
					flags_heat_protection = flags_armor_protection
			icon_state = "[armor_variation]"

		select_gamemode_skin(expected_type,,new_name)
		..()
		armor_overlays = list("lamp") //Just one for now, can add more later.
		update_icon()
		pockets.max_w_class = 3
		pockets.can_hold = list(
		"/obj/item/ammo_magazine/pistol",
		"/obj/item/ammo_magazine/rifle",
		"/obj/item/ammo_magazine/smg/m39",
		"/obj/item/ammo_magazine/sniper",
		"/obj/item/ammo_magazine/revolver",
		"/obj/item/device/flashlight",
		"/obj/item/weapon/storage/fancy/cigarettes",
		"/obj/item/weapon/combat_knife",
		"/obj/item/weapon/throwing_knife",
		"/obj/item/attachable/bayonet",
		"/obj/item/weapon/storage/box/MRE",
		"/obj/item/weapon/weldingtool",
		"/obj/item/stack/medical",
		"/obj/item/weapon/reagent_containers/hypospray",
		"/obj/item/device/healthanalyzer",
		"/obj/item/weapon/reagent_containers/pill",
		"/obj/item/weapon/reagent_containers/syringe",
		"/obj/item/weapon/storage/pill_bottle",
		 )
		pockets.max_combined_w_class = 6



	update_icon(mob/user)
		var/image/reusable/I
		I = armor_overlays["lamp"]
		overlays -= I
		cdel(I)
		if(flags_marine_armor & ARMOR_LAMP_OVERLAY)
			I = rnew(/image/reusable, flags_marine_armor & ARMOR_LAMP_ON? list('icons/Marine/marine_armor.dmi', src, "lamp-on") : list('icons/Marine/marine_armor.dmi', src, "lamp-off"))
			armor_overlays["lamp"] = I
			overlays += I
		else armor_overlays["lamp"] = null
		if(user) user.update_inv_wear_suit()

	pickup(mob/user)
		if(flags_marine_armor & ARMOR_LAMP_ON && src.loc != user)
			user.SetLuminosity(brightness_on)
			SetLuminosity(0)
		..()

	dropped(mob/user)
		if(flags_marine_armor & ARMOR_LAMP_ON && src.loc != user)
			user.SetLuminosity(-brightness_on)
			SetLuminosity(brightness_on)
			toggle_armor_light() //turn the light off
		..()

	Dispose()
		if(ismob(src.loc))
			src.loc.SetLuminosity(-brightness_on)
		else
			SetLuminosity(0)
		. = ..()

	attack_self(mob/user)
		if(!isturf(user.loc))
			user << "<span class='warning'>You cannot turn the light on while in this [user.loc].</span>" //To prevent some lighting anomalities.
			return

		if(flashlight_cooldown > world.time)
			return

		if(!ishuman(user)) return
		var/mob/living/carbon/human/H = user
		if(H.wear_suit != src) return

		toggle_armor_light(user)
		return 1

	item_action_slot_check(mob/user, slot)
		if(!ishuman(user)) return FALSE
		if(slot != WEAR_JACKET) return FALSE
		return TRUE //only give action button when armor is worn.

/obj/item/clothing/suit/storage/marine/proc/toggle_armor_light(mob/user)
	flashlight_cooldown = world.time + 20 //2 seconds cooldown every time the light is toggled
	if(flags_marine_armor & ARMOR_LAMP_ON) //Turn it off.
		if(user) user.SetLuminosity(-brightness_on)
		else SetLuminosity(0)
	else //Turn it on.
		if(user) user.SetLuminosity(brightness_on)
		else SetLuminosity(brightness_on)

	flags_marine_armor ^= ARMOR_LAMP_ON

	playsound(src,'sound/machines/click.ogg', 15, 1)
	update_icon(user)

	for(var/X in actions)
		var/datum/action/A = X
		A.update_button_icon()

/obj/item/clothing/suit/storage/marine/verb/locate_squad_tracking_beacon()
	set name = "Locate Squad Tracking Beacon"
	set category = "Object"
	set src in usr
	var/user_squad
	var/target

	var/range_limit = 30
	var/uncertainity = 2
	var/range_error_message = "<span class='notice'>ERROR: No valid squad tracking beacon in [range_limit]m range</span>"

	if(!usr.canmove || usr.stat || usr.is_mob_restrained())
		return 0

	if(locate_cooldown > world.time)
		usr << "<span class='notice'>RECALIBRATING: [round((locate_cooldown-world.time)/10)+1] seconds remaining"
		return
	locate_cooldown = world.time + 50 //5 second cooldown

	user_squad = get_squad_data_from_card(usr)
	if(!user_squad)
		usr << "<span class='notice'>ERROR: No valid user squad ID</span>"
		return


	for(var/obj/item/device/squad_tracking_beacon/B in active_tracking_beacons)
		if(B.squad == user_squad)
			target = B
			continue

	if (!target)
		usr << "[range_error_message]"
		return

	var/turf/user_turf = get_turf(usr)
	var/turf/target_turf = get_turf(target)

	if (user_turf.z != target_turf.z)
		usr << "[range_error_message]"
		return
	var/distance = get_dist(user_turf,target_turf)
	if(distance < 1)
		usr << "<span class='notice'>DIRECTION: DOWN | DISTANCE: 0m</span>"
		return
	if(distance > range_limit || !distance)
		usr << "[range_error_message]"
		return

	distance = Clamp(distance + rand(-uncertainity,uncertainity), 0, range_limit)

	usr << "<span class='notice'>DIRECTION: [uppertext(dir2text(Get_Compass_Dir(user_turf, target_turf)))] | DISTANCE: [max(0, distance-uncertainity)]-[min(range_limit, distance+uncertainity)]m</span>"





/obj/item/clothing/suit/storage/marine/MP
	name = "\improper M2 pattern MP armor"
	desc = "A standard Colonial Marines M2 Pattern Chestplate. Protects the chest from ballistic rounds, bladed objects and accidents. It has a small leather pouch strapped to it for limited storage."
	icon_state = "mp"
	armor = list(melee = 40, bullet = 70, laser = 35, energy = 20, bomb = 25, bio = 0, rad = 0)
	slowdown = SLOWDOWN_ARMOR_LIGHT
	allowed = list(/obj/item/weapon/gun/,
		/obj/item/weapon/tank/emergency_oxygen,
		/obj/item/device/flashlight,
		/obj/item/ammo_magazine/,
		/obj/item/weapon/storage/fancy/cigarettes,
		/obj/item/weapon/flame/lighter,
		/obj/item/weapon/melee/baton,
		/obj/item/weapon/handcuffs,
		/obj/item/weapon/grenade,
		/obj/item/device/binoculars,
		/obj/item/weapon/combat_knife,
		/obj/item/weapon/storage/sparepouch,
		/obj/item/device/hailer,
		/obj/item/weapon/storage/belt/gun)
	uniform_restricted = list(/obj/item/clothing/under/marine/mp)

/obj/item/clothing/suit/storage/marine/MP/WO
	icon_state = "warrant_officer"
	name = "\improper M3 pattern MP armor"
	desc = "A well-crafted suit of M3 Pattern Armor typically distributed to Chief MPs. Useful for letting your men know who is in charge."
	armor = list(melee = 50, bullet = 80, laser = 40, energy = 25, bomb = 30, bio = 0, rad = 0)
	uniform_restricted = list(/obj/item/clothing/under/marine/officer/warrant)

/obj/item/clothing/suit/storage/marine/MP/admiral
	icon_state = "admiral"
	name = "\improper M3 pattern admiral armor"
	desc = "A well-crafted suit of M3 Pattern Armor with a gold shine. It looks very expensive, but shockingly fairly easy to carry and wear."
	w_class = 3
	armor = list(melee = 50, bullet = 80, laser = 40, energy = 25, bomb = 30, bio = 0, rad = 0)
	uniform_restricted = list(/obj/item/clothing/under/marine/officer/admiral)

/obj/item/clothing/suit/storage/marine/MP/RO
	icon_state = "officer"
	name = "\improper M3 pattern officer armor"
	desc = "A well-crafted suit of M3 Pattern Armor typically found in the hands of higher-ranking officers. Useful for letting your men know who is in charge when taking to the field"
	uniform_restricted = list(/obj/item/clothing/under/marine/officer, /obj/item/clothing/under/rank/ro_suit)
	New()
		select_gamemode_skin(/obj/item/clothing/suit/storage/marine/MP/RO)
		..()

/obj/item/clothing/suit/storage/marine/sniper
	name = "\improper M3 pattern recon armor"
	desc = "A custom modified set of M3 Armor designed for recon missions."
	icon_state = "marine_sniper"
	item_state = "marine_sniper"
	armor = list(melee = 70, bullet = 45, laser = 40, energy = 25, bomb = 30, bio = 0, rad = 0)
	slowdown = SLOWDOWN_ARMOR_LIGHT
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO|LEG_RIGHT|ARM_LEFT
	flags_cold_protection = UPPER_TORSO|LOWER_TORSO|LEG_RIGHT|ARM_LEFT
	flags_heat_protection = UPPER_TORSO|LOWER_TORSO|LEG_RIGHT|ARM_LEFT
	//uniform_restricted = list(/obj/item/clothing/under/marine/sniper) //TODO : This item exists, but isn't implemented yet. Makes sense otherwise

	New(loc,expected_type 	= type,
		new_name[] 		= list(/datum/game_mode/ice_colony = "\improper M3 pattern sniper snow armor"))
		..(loc,expected_type,,new_name)

/obj/item/clothing/suit/storage/marine/sniper/jungle
	name = "\improper M3 pattern marksman armor"
	icon_state = "marine_sniperm"
	item_state = "marine_sniperm"
	slowdown = SLOWDOWN_ARMOR_LIGHT
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO|LEGS|ARMS
	flags_cold_protection = UPPER_TORSO|LOWER_TORSO|LEGS|ARMS
	flags_heat_protection = UPPER_TORSO|LOWER_TORSO|LEGS|ARMS

	New(loc,expected_type 	= type,
		new_name[] 		= list(/datum/game_mode/ice_colony = "\improper M3 pattern marksman snow armor"))
		..(loc,expected_type,,new_name)

/obj/item/clothing/suit/storage/marine/smartgunner
	name = "M56 combat harness"
	desc = "A heavy protective vest designed to be worn with the M56 Smartgun System. \nIt has specially designed straps and reinforcement to carry the Smartgun and accessories."
	icon = 'icons/Marine/marine_armor.dmi'
	icon_state = "8"
	item_state = "armor"
	icon_override = 'icons/Marine/marine_armor.dmi'
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO|LEGS
	flags_cold_protection = UPPER_TORSO|LOWER_TORSO|LEGS
	flags_heat_protection = UPPER_TORSO|LOWER_TORSO|LEGS
	armor = list(melee = 55, bullet = 75, laser = 35, energy = 35, bomb = 35, bio = 0, rad = 0)
	slowdown = SLOWDOWN_ARMOR_LIGHT
	allowed = list(/obj/item/weapon/tank/emergency_oxygen,
					/obj/item/device/flashlight,
					/obj/item/ammo_magazine,
					/obj/item/device/mine,
					/obj/item/weapon/combat_knife,
					/obj/item/weapon/gun/smartgun,
					/obj/item/weapon/storage/sparepouch)
	New()
		select_gamemode_skin(type)
		..()
	/*
	New(loc,expected_type 	= type,
		new_name[] 		= list(/datum/game_mode/ice_colony = "\improper M56 combat harness"))
		..(loc,expected_type,,new_name)
		..()
	*/

/obj/item/clothing/suit/storage/marine/leader
	name = "\improper B12 pattern leader armor"
	desc = "A lightweight suit of carbon fiber body armor built for quick movement. Designed in a lovely forest green. Use it to toggle the built-in flashlight."
	icon_state = "7"
	armor = list(melee = 50, bullet = 60, laser = 45, energy = 40, bomb = 40, bio = 15, rad = 15)

	New(loc,expected_type 	= type,
		new_name[] 		= list(/datum/game_mode/ice_colony = "\improper B12 pattern leader snow armor"))
		..(loc,expected_type,new_name)

/obj/item/clothing/suit/storage/marine/specialist
	name = "\improper B18 defensive armor"
	desc = "A heavy, rugged set of armor plates for when you really, really need to not die horribly. Slows you down though.\nComes with a tricord injector in each arm guard."
	icon_state = "xarmor"
	armor = list(melee = 95, bullet = 110, laser = 80, energy = 80, bomb = 75, bio = 20, rad = 20)
	slowdown = SLOWDOWN_ARMOR_HEAVY
	var/injections = 2
	unacidable = 1

	New(loc,expected_type 	= type,
		new_name[] 		= list(/datum/game_mode/ice_colony = "\improper B18 defensive snow armor"))
		..(loc,expected_type,new_name)

/obj/item/clothing/suit/storage/marine/specialist/verb/inject()
	set name = "Create Injector"
	set category = "Object"
	set src in usr

	if(!usr.canmove || usr.stat || usr.is_mob_restrained())
		return 0

	if(!injections)
		usr << "Your armor is all out of injectors."
		return 0

	if(usr.get_active_hand())
		usr << "Your active hand must be empty."
		return 0

	usr << "You feel a faint hiss and an injector drops into your hand."
	var/obj/item/weapon/reagent_containers/hypospray/autoinjector/tricord/O = new(usr)
	usr.put_in_active_hand(O)
	injections--
	playsound(src,'sound/machines/click.ogg', 15, 1)
	return


//=============================//PMCS\\==================================\\
//=======================================================================\\

/obj/item/clothing/suit/storage/marine/veteran
	flags_marine_armor = ARMOR_LAMP_OVERLAY

/obj/item/clothing/suit/storage/marine/veteran/PMC
	name = "\improper M4 pattern PMC armor"
	desc = "A modification of the standard Armat Systems M3 armor. Designed for high-profile security operators and corporate mercenaries in mind."
	icon = 'icons/PMC/PMC.dmi'
	icon_override = 'icons/PMC/PMC.dmi'
	item_state = "armor"
	icon_state = "pmc_armor"
	armor = list(melee = 55, bullet = 62, laser = 42, energy = 38, bomb = 40, bio = 15, rad = 15)
	slowdown = SLOWDOWN_ARMOR_LIGHT
	allowed = list(/obj/item/weapon/gun/,
		/obj/item/weapon/tank/emergency_oxygen,
		/obj/item/device/flashlight,
		/obj/item/ammo_magazine/,
		/obj/item/weapon/melee/baton,
		/obj/item/weapon/handcuffs,
		/obj/item/weapon/storage/fancy/cigarettes,
		/obj/item/weapon/flame/lighter,
		/obj/item/weapon/grenade,
		/obj/item/weapon/storage/bible,
		/obj/item/weapon/claymore/mercsword/machete,
		/obj/item/weapon/flamethrower,
		/obj/item/weapon/combat_knife)
	uniform_restricted = list(/obj/item/clothing/under/marine/veteran/PMC)

/obj/item/clothing/suit/storage/marine/veteran/PMC/leader
	name = "\improper M4 pattern PMC leader armor"
	desc = "A modification of the standard Armat Systems M3 armor. Designed for high-profile security operators and corporate mercenaries in mind. This particular suit looks like it belongs to a high-ranking officer."
	icon = 'icons/PMC/PMC.dmi'
	icon_state = "officer_armor"
	uniform_restricted = list(/obj/item/clothing/under/marine/veteran/PMC/leader)

/obj/item/clothing/suit/storage/marine/veteran/PMC/sniper
	name = "\improper M4 pattern PMC sniper armor"
	icon = 'icons/PMC/PMC.dmi'
	icon_override = 'icons/PMC/PMC.dmi'
	item_state = "pmc_sniper"
	icon_state = "pmc_sniper"
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO|LEGS
	flags_cold_protection = UPPER_TORSO|LOWER_TORSO|LEGS
	flags_heat_protection = UPPER_TORSO|LOWER_TORSO|LEGS
	armor = list(melee = 60, bullet = 70, laser = 50, energy = 60, bomb = 65, bio = 10, rad = 10)
	flags_inventory = BLOCKSHARPOBJ|HIDELOWHAIR

/obj/item/clothing/suit/storage/marine/smartgunner/veteran/PMC
	name = "\improper PMC gunner armor"
	desc = "A modification of the standard Armat Systems M3 armor. Hooked up with harnesses and straps allowing the user to carry an M56 Smartgun."
	icon = 'icons/PMC/PMC.dmi'
	icon_override = 'icons/PMC/PMC.dmi'
	item_state = "heavy_armor"
	icon_state = "heavy_armor"
	slowdown = SLOWDOWN_ARMOR_HEAVY
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS
	flags_cold_protection = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS
	flags_heat_protection = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS
	armor = list(melee = 85, bullet = 85, laser = 55, energy = 65, bomb = 70, bio = 20, rad = 20)

/obj/item/clothing/suit/storage/marine/veteran/PMC/commando
	name = "\improper PMC commando armor"
	desc = "A heavily armored suit built by who-knows-what for elite operations. It is a fully self-contained system and is heavily corrosion resistant."
	icon = 'icons/PMC/PMC.dmi'
	item_state = "commando_armor"
	icon_state = "commando_armor"
	icon_override = 'icons/PMC/PMC.dmi'
	slowdown = SLOWDOWN_ARMOR_VERY_HEAVY
	armor = list(melee = 90, bullet = 120, laser = 100, energy = 90, bomb = 90, bio = 100, rad = 100)
	unacidable = 1
	uniform_restricted = list(/obj/item/clothing/under/marine/veteran/PMC/commando)

//===========================//DISTRESS\\================================\\
//=======================================================================\\

/obj/item/clothing/suit/storage/marine/veteran/bear
	name = "\improper H1 Iron Bears vest"
	desc = "A protective vest worn by Iron Bears mercenaries."
	icon = 'icons/PMC/PMC.dmi'
	icon_override = 'icons/PMC/PMC.dmi'
	item_state = "bear_armor"
	icon_state = "bear_armor"
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO
	armor = list(melee = 70, bullet = 70, laser = 50, energy = 60, bomb = 50, bio = 10, rad = 10)
	slowdown = SLOWDOWN_ARMOR_VERY_LIGHT
	uniform_restricted = list(/obj/item/clothing/under/marine/veteran/bear)

/obj/item/clothing/suit/storage/marine/veteran/dutch
	name = "\improper D2 armored vest"
	desc = "A protective vest worn by some seriously experienced mercs."
	icon = 'icons/PMC/PMC.dmi'
	icon_override = 'icons/PMC/PMC.dmi'
	item_state = "dutch_armor"
	icon_state = "dutch_armor"
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO
	armor = list(melee = 70, bullet = 85, laser = 55,energy = 65, bomb = 70, bio = 10, rad = 10)
	slowdown = SLOWDOWN_ARMOR_VERY_LIGHT
	uniform_restricted = list(/obj/item/clothing/under/marine/veteran/dutch)




//===========================//U.P.P\\================================\\
//=====================================================================\\

/obj/item/clothing/suit/storage/faction
	flags_atom = FPRINT|CONDUCT
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS
	flags_cold_protection = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS
	flags_heat_protection = UPPER_TORSO|LOWER_TORSO|ARMS|LEGS
	min_cold_protection_temperature = ARMOR_min_cold_protection_temperature
	max_heat_protection_temperature = ARMOR_max_heat_protection_temperature
	blood_overlay_type = "armor"
	armor = list(melee = 50, bullet = 40, laser = 35, energy = 20, bomb = 25, bio = 0, rad = 0)
	siemens_coefficient = 0.7
	slowdown = SLOWDOWN_ARMOR_MEDIUM
	allowed = list(/obj/item/weapon/gun/,
		/obj/item/weapon/tank/emergency_oxygen,
		/obj/item/device/flashlight,
		/obj/item/ammo_magazine/,
		/obj/item/weapon/grenade,
		/obj/item/weapon/flamethrower,
		/obj/item/device/binoculars,
		/obj/item/weapon/combat_knife,
		/obj/item/weapon/storage/sparepouch,
		/obj/item/weapon/storage/large_holster/machete)
	var/brightness_on = 5 //Average attachable pocket light
	var/flashlight_cooldown = 0 //Cooldown for toggling the light
	var/locate_cooldown = 0 //Cooldown for SL locator
	var/armor_overlays["lamp"]
	actions_types = list(/datum/action/item_action/toggle)
	var/flags_faction_armor = ARMOR_LAMP_OVERLAY

	New()
		..()
		armor_overlays = list("lamp")
		update_icon()

	update_icon(mob/user)
		var/image/reusable/I
		I = armor_overlays["lamp"]
		overlays -= I
		cdel(I)
		if(flags_faction_armor & ARMOR_LAMP_OVERLAY)
			I = rnew(/image/reusable, flags_faction_armor & ARMOR_LAMP_ON? list('icons/Marine/marine_armor.dmi', src, "lamp-on") : list('icons/Marine/marine_armor.dmi', src, "lamp-off"))
			armor_overlays["lamp"] = I
			overlays += I
		else armor_overlays["lamp"] = null
		if(user) user.update_inv_wear_suit()

	pickup(mob/user)
		if(flags_faction_armor & ARMOR_LAMP_ON && src.loc != user)
			user.SetLuminosity(brightness_on)
			SetLuminosity(0)
		..()

	dropped(mob/user)
		if(flags_faction_armor & ARMOR_LAMP_ON && src.loc != user)
			user.SetLuminosity(-brightness_on)
			SetLuminosity(brightness_on)
			toggle_armor_light() //turn the light off
		..()

	Dispose()
		if(ismob(src.loc))
			src.loc.SetLuminosity(-brightness_on)
		else
			SetLuminosity(0)
		. = ..()

	attack_self(mob/user)
		if(!isturf(user.loc))
			user << "<span class='warning'>You cannot turn the light on while in this [user.loc].</span>" //To prevent some lighting anomalities.
			return

		if(flashlight_cooldown > world.time)
			return

		if(!ishuman(user)) return
		var/mob/living/carbon/human/H = user
		if(H.wear_suit != src) return

		toggle_armor_light(user)
		return 1

	item_action_slot_check(mob/user, slot)
		if(!ishuman(user)) return FALSE
		if(slot != WEAR_JACKET) return FALSE
		return TRUE //only give action button when armor is worn.

/obj/item/clothing/suit/storage/faction/proc/toggle_armor_light(mob/user)
	flashlight_cooldown = world.time + 20 //2 seconds cooldown every time the light is toggled
	if(flags_faction_armor & ARMOR_LAMP_ON) //Turn it off.
		if(user) user.SetLuminosity(-brightness_on)
		else SetLuminosity(0)
	else //Turn it on.
		if(user) user.SetLuminosity(brightness_on)
		else SetLuminosity(brightness_on)

	flags_faction_armor ^= ARMOR_LAMP_ON

	playsound(src,'sound/machines/click.ogg', 15, 1)
	update_icon(user)

	for(var/X in actions)
		var/datum/action/A = X
		A.update_button_icon()

/obj/item/clothing/suit/storage/faction/UPP
	name = "\improper UM5 personal armor"
	desc = "Standard body armor of the UPP military, the UM5 (Union Medium MK5) is a medium body armor, roughly on par with the venerable M3 pattern body armor in service with the USCM. Unlike the M3, however, the plate has a heavier neckplate, but unfortunately restricts movement slightly more. This has earned many UA members to refer to UPP soldiers as 'tin men'."
	icon = 'icons/PMC/PMC.dmi'
	icon_override = 'icons/PMC/PMC.dmi'
	item_state = "upp_armor"
	icon_state = "upp_armor"
	slowdown = SLOWDOWN_ARMOR_MEDIUM
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO
	armor = list(melee = 60, bullet = 60, laser = 50, energy = 60, bomb = 40, bio = 10, rad = 10)
	uniform_restricted = list(/obj/item/clothing/under/marine/veteran/UPP)

/obj/item/clothing/suit/storage/faction/UPP/commando
	name = "\improper UM5CU personal armor"
	desc = "A modification of the UM5, designed for stealth operations."
	item_state = "upp_armor_commando"
	icon_state = "upp_armor_commando"
	slowdown = SLOWDOWN_ARMOR_LIGHT

/obj/item/clothing/suit/storage/faction/UPP/heavy
	name = "\improper UH7 heavy plated armor"
	desc = "An extremely heavy duty set of body armor in service with the UPP military, the UH7 (Union Heavy MK5) is known for being a rugged set of armor, capable of taking immesnse punishment. Although the armor doesn't protect certain areas, it provides unmatchable protection from the front, which UPP engineers summerized as the most likely target for enemy fire. In order to cut costs, the head shielding in the MK6 has been stripped down a bit in the MK7, but this comes at much more streamlined production.  "
	icon = 'icons/PMC/PMC.dmi'
	icon_override = 'icons/PMC/PMC.dmi'
	item_state = "upp_armor_heavy"
	icon_state = "upp_armor_heavy"
	slowdown = SLOWDOWN_ARMOR_HEAVY
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO|LEGS
	armor = list(melee = 85, bullet = 85, laser = 50, energy = 60, bomb = 60, bio = 10, rad = 10)
	uniform_restricted = list(/obj/item/clothing/under/marine/veteran/UPP)

/obj/item/clothing/suit/storage/marine/smartgunner/UPP
	name = "\improper UH7 heavy plated armor"
	desc = "An extremely heavy duty set of body armor in service with the UPP military, the UH7 (Union Heavy MK5) is known for being a rugged set of armor, capable of taking immesnse punishment. Although the armor doesn't protect certain areas, it provides unmatchable protection from the front, which UPP engineers summerized as the most likely target for enemy fire. In order to cut costs, the head shielding in the MK6 has been stripped down a bit in the MK7, but this comes at much more streamlined production.  "
	icon = 'icons/PMC/PMC.dmi'
	icon_override = 'icons/PMC/PMC.dmi'
	item_state = "upp_armor_heavy"
	icon_state = "upp_armor_heavy"
	slowdown = SLOWDOWN_ARMOR_HEAVY
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO
	armor = list(melee = 85, bullet = 85, laser = 50, energy = 60, bomb = 60, bio = 10, rad = 10)
	uniform_restricted = list(/obj/item/clothing/under/marine/veteran/UPP)

//===========================//FREELANCER\\================================\\
//=====================================================================\\

/obj/item/clothing/suit/storage/faction/freelancer
	name = "\improper freelancer cuirass"
	desc = "A armored protective chestplate scrapped together from various plates. It keeps up remarkably well, as the craftsmanship is solid, and the design mirrors such armors in the UPP and the USCM. The many skilled craftsmen in the freelancers ranks produce these vests at a rate about one a month."
	icon = 'icons/PMC/PMC.dmi'
	icon_override = 'icons/PMC/PMC.dmi'
	item_state = "freelancer_armor"
	icon_state = "freelancer_armor"
	slowdown = SLOWDOWN_ARMOR_LIGHT
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO
	armor = list(melee = 60, bullet = 60, laser = 50, energy = 60, bomb = 40, bio = 10, rad = 10)
	uniform_restricted = list(/obj/item/clothing/under/marine/veteran/freelancer)

/obj/item/clothing/suit/storage/militia
	name = "\improper colonial militia hauberk"
	desc = "The hauberk of a colonist militia member, created from boiled leather and some modern armored plates. While not the most powerful form of armor, and primitive compared to most modern suits of armor, it gives the wearer almost perfect mobility, which suits the needs of the local colonists. It is also quick to don, easy to hide, and cheap to produce in large workshops."
	icon = 'icons/PMC/PMC.dmi'
	icon_override = 'icons/PMC/PMC.dmi'
	item_state = "rebel_armor"
	icon_state = "rebel_armor"
	slowdown = SLOWDOWN_ARMOR_VERY_LIGHT
	flags_armor_protection = UPPER_TORSO|LOWER_TORSO|LEGS
	armor = list(melee = 40, bullet = 40, laser = 40, energy = 30, bomb = 60, bio = 30, rad = 30)
	uniform_restricted = list(/obj/item/clothing/under/colonist)
	allowed = list(/obj/item/weapon/gun/,
		/obj/item/weapon/tank/emergency_oxygen,
		/obj/item/device/flashlight,
		/obj/item/ammo_magazine/,
		/obj/item/weapon/grenade,
		/obj/item/weapon/flamethrower,
		/obj/item/device/binoculars,
		/obj/item/weapon/combat_knife,
		/obj/item/weapon/storage/sparepouch,
		/obj/item/weapon/storage/large_holster/machete,
		/obj/item/weapon/baseballbat,
		/obj/item/weapon/baseballbat/metal)
	flags_cold_protection = UPPER_TORSO|LOWER_TORSO|LEGS|FEET|ARMS|HANDS
	min_cold_protection_temperature = SPACE_SUIT_min_cold_protection_temperature

/obj/item/clothing/suit/storage/CMB
	name = "\improper CMB jacket"
	desc = "A green jacket worn by crew on the Colonial Marshals."
	icon_state = "CMB_jacket"
	item_state = "CMB_jacket"
	blood_overlay_type = "coat"
	flags_armor_protection = UPPER_TORSO|ARMS

/obj/item/clothing/suit/storage/RO
	name = "\improper RO jacket"
	desc = "A green jacket worn by USCM personnel. The back has the flag of the United Americas on it."
	icon_state = "RO_jacket"
	item_state = "RO_jacket"
	blood_overlay_type = "coat"
	flags_armor_protection = UPPER_TORSO|ARMS
