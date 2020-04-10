iblocks = {}
iblocks.activities = {}
minetest.register_privilege("iblocks", "Use the Interactive Blocks")
iblocks.get_activity = function(pos)
	return iblocks.activities[minetest.serialize(pos)]
end
iblocks.set_activity = function(pos, activity)
	iblocks.activities[minetest.serialize(pos)] = activity
end
iblocks.pos_to_str = function(pos)
	return " Position: (" .. pos.x .. ", " .. pos.y .. ", " .. pos.z .. ")"
end
iblocks.error = function(name, message)
	minetest.chat_send_player(name, minetest.colorize("#FF2E00", "Fehler: " .. message))
end
iblocks.protected = function(pos, name)
	local meta = minetest.get_meta(pos)
	if not minetest.check_player_privs(name, {protection_bypass}) and meta:get_string("owner") ~= "" and meta:get_string("owner") ~= name then
		iblocks.error(name, "Dieser Block gehört nicht dir!")
		return true
	else
		return false
	end
end
iblocks.lackspriv = function(name)
	if minetest.check_player_privs(name, {iblocks = true}) then
		return false
	else
		iblocks.error(name, "Dir fehlt das iblocks Privileg!")
		return true
	end
end
iblocks.get_player_activity = function(name)
	for _, a in pairs(iblocks.activities) do
		if a.player == name then
			return a
		end
	end
	return nil
end
iblocks.enable = function(activity)
	local old_activity = iblocks.get_player_activity(activity.player)
	if iblocks.protected(activity.pos, activity.player) or iblocks.lackspriv(activity.player) then
		return false
	elseif iblocks.disable(activity.pos) then
		return false
	elseif old_activity then
		iblocks.error(activity.player, old_activity.active .. iblocks.pos_to_str(old_activity.pos))
		return false
	else
		iblocks.set_activity(activity.pos, activity)
		minetest.chat_send_player(activity.player, minetest.colorize("#3EFF00", activity.enable .. iblocks.pos_to_str(activity.pos)))
		return true
	end
end
iblocks.disable = function(pos)
	local activity = iblocks.get_activity(pos)
	if activity then
		minetest.chat_send_player(activity.player, minetest.colorize("#FF492A", activity.disable .. iblocks.pos_to_str(activity.pos)))
		iblocks.set_activity(pos, nil)
		return true
	end
	return false
end
minetest.register_node("iblocks:textblock", {
	description = "Textblock",
	tiles = {"iblocks_textblock.png"},
	after_place_node = function(pos, player)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", player:get_player_name())
		meta:set_string("infotext", "Textblock von " .. player:get_player_name() .. " - Rechtsclick für Eingabe, Linksklick für Ausgabe, Benutze eine Axt zum Abbauen")
	end,
	on_punch = function(pos, node, player, pointed_thing)
		if iblocks.protected(pos, player:get_player_name()) or iblocks.lackspriv(player:get_player_name()) or player:get_wielded_item():get_name():find("axe") then
			return true
		else
			local meta = minetest.get_meta(pos)
			if meta:get_string("data") == "" then
				iblocks.error(player:get_player_name(), "Dieser Textblock enthält noch keinen Text.")
			else
				minetest.chat_send_all(minetest.colorize("#2AA7FF", "[Textblock von ") .. minetest.colorize("#0EFF00", player:get_player_name()) .. minetest.colorize("#2AA7FF", "]:\n   ") .. meta:get_string("data"))
			end
		end
	end,
	on_rightclick = function(pos, node, player, pointed_thing)
		iblocks.enable({pos = pos, name = "textblock", player = player:get_player_name(), active = "Du bearbeitest bereits einen Textblock!", disable = "Textblock ausgeschaltet.", enable = "Textblock eingeschaltet."})
	end,
	on_destruct = function(pos, player)
		iblocks.disable(pos)
	end,
	can_dig = function(pos, player)
		return not iblocks.protected(pos, player:get_player_name())
	end,
	groups = {choppy = 3}
})
minetest.register_on_chat_message(function(name, message)
	local activity = iblocks.get_player_activity(name)
	if activity then
		local meta = minetest.get_meta(activity.pos)
		if activity.name == "textblock" then
			meta:set_string("data", meta:get_string("data") .. message .. "\n   ")
			minetest.chat_send_player(name, minetest.colorize("#2AA7FF", "Die Nachricht wurde in den Textblock geschrieben: ") .. message)
			return true
		end
	end
end)
