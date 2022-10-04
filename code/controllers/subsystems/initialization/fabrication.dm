SUBSYSTEM_DEF(fabrication)
	name = "Fabrication"
	flags = SS_NO_FIRE
	init_order = SS_INIT_MISC_LATE

	var/list/recipes =    list()
	var/list/categories = list()
	var/list/crafting_procedures_by_type = list()

/datum/controller/subsystem/fabrication/Initialize()
	for(var/R in subtypesof(/datum/fabricator_recipe))
		var/datum/fabricator_recipe/recipe = new R
		for(var/fab_type in recipe.fabricator_types)
			LAZYADD(recipes[fab_type], recipe)
			LAZYDISTINCTADD(categories[fab_type], recipe.category)
	var/list/all_crafting_handlers = decls_repository.get_decls_of_subtype(/decl/crafting_stage)
	for(var/hid in all_crafting_handlers)
		var/decl/crafting_stage/handler = all_crafting_handlers[hid]
		if(ispath(handler.begins_with_object_type))
			LAZYDISTINCTADD(crafting_procedures_by_type[handler.begins_with_object_type], handler)
	. = ..()

/datum/controller/subsystem/fabrication/proc/get_categories(var/fab_type)
	. = categories[fab_type]

/datum/controller/subsystem/fabrication/proc/get_recipes(var/fab_type)
	. = recipes[fab_type]

/datum/controller/subsystem/fabrication/proc/find_crafting_recipes(var/_type)
	if(isnull(crafting_procedures_by_type[_type]))
		crafting_procedures_by_type[_type] = FALSESUBSYSTEM_DEF(fabrication)
	name = "Fabrication"
	flags = SS_NO_FIRE
	init_order = SS_INIT_MISC_LATE

	var/static/tmp/list/recipes = list()
	var/static/tmp/list/categories = list()
	var/static/tmp/list/stages_by_type = list()


/datum/controller/subsystem/fabrication/UpdateStat(time)
	return


/datum/controller/subsystem/fabrication/Initialize()
	for (var/datum/fabricator_recipe/recipe as anything in subtypesof(/datum/fabricator_recipe))
		recipe = new recipe
		if (!recipe.name)
			continue
		for (var/type in recipe.fabricator_types)
			if (!recipes[type])
				recipes[type] = list()
			recipes[type] += recipe
			if (!categories[type])
				categories[type] = list()
			categories[type] |= recipe.category
	var/list/stages = decls_repository.get_decls_of_subtype(/decl/crafting_stage)
	for (var/id in stages)
		var/decl/crafting_stage/stage = stages[id]
		var/type = stage.begins_with_object_type
		if (!ispath(type))
			continue
		if (!stages_by_type[type])
			stages_by_type[type] = list()
		stages_by_type[type] |= stage


/datum/controller/subsystem/fabrication/proc/get_categories(type)
	return categories[type]


/datum/controller/subsystem/fabrication/proc/get_recipes(type)
	return recipes[type]


/datum/controller/subsystem/fabrication/proc/find_crafting_recipes(type)
	if (isnull(stages_by_type[type]))
		stages_by_type[type] = FALSE
		for (var/match in stages_by_type)
			if (ispath(type, match))
				stages_by_type[type] = stages_by_type[match]
				break
	return stages_by_type[type]


/datum/controller/subsystem/fabrication/proc/try_craft_with(obj/item/target, obj/item/tool, mob/user)
	var/turf/turf = get_turf(target)
	if (!turf)
		return
	var/list/stages = SSfabrication.find_crafting_recipes(target.type)
	for (var/decl/crafting_stage/stage in stages)
		if (stage.can_begin_with(target) && stage.is_appropriate_tool(tool))
			var/obj/item/crafting_holder/crafting = new (turf, stage, target, tool, user)
			if (stage.progress_to(tool, user, crafting))
				return crafting
			qdel(crafting)
