-- * vars
local mrot_lookat = mrotation.set_look_at
local mvector3_normalize = mvector3.normalize

local equipmentList = {
	[1] = "DoctorBagBase",
	[2] = "AmmoBagBase",
	[3] = "FirstAidKitBase",
	[4] = "TripMineBase",
	-- ! sentry guns require an owner unit as first arg, they also tend to crash the game
	-- [5] = "SentryGunBase",
	-- ! ECMs, BBCs* and Grenade Cases stay in place once they are drained. high performance impact
	-- [6] = "ECMJammerBase",
	-- [7] = "BodyBagsBagBase",
	-- [8] = "GrenadeCrateBase",
}

-- * helpers
function getUnitCrossHair(unit)
	if not alive(unit) then
		return
	end

	local from = unit:movement():m_head_pos()

	local to = Vector3()
	mvector3.set(to, unit:movement():m_head_rot():y())
	mvector3.multiply(to, 20000)
	mvector3.add(to, from)

	local colRay = World:raycast("ray", from, to, "slot_mask", managers.slot:get_mask("bullet_impact_targets"))
	if not colRay then
		return
	end

	return colRay.hit_position
end

function getPosition(unit, use_cross)
	if not alive(unit) then
		return nil
	end

	return use_cross and getUnitCrossHair(unit) or unit:position()
end

function spawnUnit(unit, pos, rot)
	if type(unit) == "string" then
		if Network:is_server() then
			World:spawn_unit(Idstring(unit), pos, rot)
		end
		return
	end

	local index = unit
	if type(unit) == "boolean" then
		index = unit and 1 or 2
	end

	if Network:is_server() then
		local eClass = _G[equipmentList[index] or "DoctorBagBase"]
		if not eClass then
			return
		end

		local spawned_unit = eClass.spawn(pos, rot, 1, index == 5 and pUnit or nil)

		if index == 4 then
			spawned_unit:base():set_active(true, managers.player:player_unit())
		end
	else
		-- rotation is normalized :(
		-- if index == 4 then
		-- 	managers.network:session():send_to_host("place_trip_mine", pos, rot, 1)
		-- 	return
		-- end

		managers.network
			:session()
			:send_to_host("place_deployable_bag", equipmentList[index] or "DoctorBagBase", pos, rot, 1)
	end
end

function getCubesphereWithRotation(n)
	local ret, pos, rot = {}
	local nm, nx = -n, n
	for x = nm, nx do
		for y = nm, nx do
			for z = nm, nx do
				if x == nm or x == nx or y == nm or y == nx or z == nm or z == nx then
					pos = Vector3(x, y, z)
					mvector3_normalize(pos)
					rot = Rotation(0, 0, 0)
					mrot_lookat(rot, pos, math.UP)
					table.insert(ret, { pos = pos, rot = rot })
				end
			end
		end
	end

	return ret
end

function getWallPointsWithRotation(pUnit, use_cross, x, y, separation)
	local position = getPosition(pUnit, use_cross)
	if not position then
		return
	end

	if not x or not y or x <= 0 or y <= 0 then
		x, y = 14, 14
	end

	if not separation or separation <= 0 then
		separation = 10
	end

	local ret = {}
	local yaw = pUnit:movement():m_head_rot():yaw()
	local rot = Rotation(yaw, 0, 0)

	local hcenter = x * separation / 2
	local newrot = Rotation(yaw - 90, 0, 0)
	local newpos = position - newrot:y() * hcenter
	yaw = yaw + 180

	for xx = 1, x do
		for yy = 1, y do
			local item = { pos = Vector3(newpos.x, newpos.y, newpos.z + yy * separation), rot = rot }
			table.insert(ret, item)
		end
		newpos = newpos + newrot:y() * separation
	end
	return ret
end

function getSpherePointsWithRotation(position, n, radius)
	if n == 0 then
		return
	end

	-- Provisorio --
	local ret = {}
	local xxp, yyp = (360 / n), (180 / n)

	for xx = 1, n do
		for yy = 1, n do
			local newrot = Rotation(xxp * xx, 90 - (yyp * yy - (yyp / 2)), 0)
			local newpos = position + newrot:y() * radius
			local item = { pos = newpos, rot = newrot }
			table.insert(ret, item)
		end
	end

	return ret
end

function getPositionsDistance(a_pos, b_pos)
	local dx = b_pos.x - a_pos.x
	local dy = b_pos.y - a_pos.y
	local dz = b_pos.z - a_pos.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function spawnRound(pUnit, use_cross, unitId)
	local position = getPosition(pUnit, use_cross)
	if not position then
		return
	end

	if unitId == nil then
		unitId = true
	end

	position = position + Vector3(0, 0, 100)
	local n = 10
	for xx = 1, n + 2 do
		local rot, newpos
		if xx > n then
			rot = Rotation(0, -270 + 180 * (xx - n), 0)
			newpos = position
		else
			rot = Rotation(180 - (360 / n) * xx, 0, 0)
			newpos = position + rot:y() * 10
		end

		spawnUnit(unitId, newpos, rot)

		if type(unitId) == "boolean" then
			unitId = not unitId
		end
	end
end

-- * shapes
function spawnStairUp(pUnit, use_cross, unitId, steps)
	local position = getPosition(pUnit, use_cross)
	if not position then
		return
	end

	local baseyaw = pUnit:movement():m_head_rot():yaw() + 90

	if not tonumber(steps) then
		steps = 75
	end

	if unitId == nil then
		unitId = true
	end

	for zz = 1, steps do
		for xx = 1, 2 do
			local angle = baseyaw + zz * 8
			local radius = xx * 60
			local x = math.cos(angle) * radius
			local y = math.sin(angle) * radius
			local pos = position + Vector3(x, y, zz * 15)

			spawnUnit(unitId, pos, Rotation(angle, 0, 0))

			if type(unitId) == "boolean" then
				unitId = not unitId
			end
		end
	end
end

function spawnCircle(pUnit, use_cross, unitId, amount, radius)
	local position = getPosition(pUnit, use_cross)
	if not position then
		return
	end

	local pHead = pUnit:movement():m_head_rot()
	local rotation = Rotation(pHead and pHead:yaw(), 0, 0)

	if unitId == nil then
		unitId = true
	end

	if amount == nil then
		amount = 8
	end

	if radius == nil then
		radius = 175
	end

	local basepos = position - rotation:y() * radius
	local baseyaw = rotation:yaw()
	for x = 1, amount do
		local newrot = Rotation(baseyaw, 0, 0)
		position = basepos + newrot:y() * radius

		spawnUnit(unitId, position, Rotation(baseyaw, ((unitId == 4) and 90) or 0, 0))

		if type(unitId) == "boolean" then
			unitId = not unitId
		end

		baseyaw = baseyaw + (360 / amount)
	end
end

function spawnCubeSphere(pUnit, use_cross, unitId, n, size, altitude)
	if not alive(pUnit) then
		return
	end

	local position = getPosition(pUnit, use_cross)
	if not position then
		return
	end

	local pHead = pUnit:movement():m_head_rot()
	local rotation = Rotation(pHead and pHead:yaw() or 0, 0, 0)

	local sphere = getCubesphereWithRotation(n or 3) -- ((n*2)+1)^3

	if not size then
		size = 150
	end

	if not altitude then
		altitude = 0
	end

	if unitId == nil then
		unitId = true
	end

	for x = 1, #sphere do
		local pos = position + (sphere[x].pos * size) + Vector3(0, 0, size + altitude)
		local rot = Rotation(sphere[x].rot:yaw(), sphere[x].rot:pitch() + 90, sphere[x].rot:roll())

		spawnUnit(unitId, pos, rot)

		if type(unitId) == "boolean" then
			unitId = not unitId
		end
	end
end

function spawnWall(pUnit, use_cross, unitId, x, y, separation)
	local wall = getWallPointsWithRotation(pUnit, use_cross, x, y, separation)
	if not wall then
		return
	end

	if unitId == nil then
		unitId = true
	end

	for _, v in pairs(wall) do
		spawnUnit(unitId, v.pos, Rotation(v.rot:yaw(), 0, 0))

		if type(unitId) == "boolean" then
			unitId = not unitId
		end
	end
end

function spawnPortal(pUnit, use_cross, unitId, tilt, distance)
	local position = getPosition(pUnit, use_cross)
	if not position then
		return
	end

	if unitId == nil then
		unitId = true
	end

	if not tilt then
		tilt = 0
	end

	if not distance then
		distance = 250
	end

	position = position + Vector3(0, 0, 250)
	local rot = pUnit:movement():m_head_rot()
	local degree = -90
	while degree <= 90 do
		local newrot = Rotation(rot:yaw() + 90, degree, tilt)
		local newpos = position + newrot:y() * distance

		spawnUnit(unitId, newpos, Rotation(newrot:yaw(), degree - 180, 0))

		if type(unitId) == "boolean" then
			unitId = not unitId
		end

		degree = degree + 18
	end

	local degree = -72
	while degree <= 72 do
		local newrot = Rotation(rot:yaw() - 90, degree, -tilt)
		local newpos = position + newrot:y() * distance

		spawnUnit(unitId, newpos, Rotation(newrot:yaw(), degree - 180, 0))

		if type(unitId) == "boolean" then
			unitId = not unitId
		end

		degree = degree + 18
	end
end

function spawnVoid(pUnit, use_cross, unitId)
	local position = getPosition(pUnit, use_cross)
	if not position then
		return
	end

	if unitId == nil then
		unitId = true
	end

	for _, data in pairs(getSpherePointsWithRotation(position + Vector3(0, 0, 145), 5, 25)) do
		spawnUnit(unitId, data.pos, data.rot)

		if type(unitId) == "boolean" then
			unitId = not unitId
		end
	end
end

function spawnFromFile(fileName, pUnit, use_cross, unitId)
	local file = io.open(CommandManager._path .. "shapes/" .. tostring(fileName) .. ".txt", "r")

	if not file then
		return log("File does not exist")
	end

	local position = getPosition(pUnit, use_cross)
	if not position then
		return
	end

	if unitId == nil then
		unitId = true
	end

	local x, y, z
	for line in file:lines() do
		x, y, z = line:match("([^,]+) ([^,]+) ([^,]+)")
		if not y and not z then
			x, y, z = line:match("([^,]+),([^,]+),([^,]+)")
		end

		x, y, z = tonumber(x), tonumber(y), tonumber(z)

		if not x or not y or not z then
			return
		end

		local basepos = position - Vector3(
				0,
				0,
				-3000 --[[height]]
			)
		local pos = basepos + (Vector3(x, y, z) * 2200)
		local rot = Rotation(0, 0, 0)

		if getPositionsDistance(pos, basepos) > 600 then
			mrot_lookat(rot, Vector3(x, y, z), math.UP)
		end

		rot = Rotation(rot:yaw(), unitId == 4 and 90 or rot:pitch(), rot:roll())

		spawnUnit(unitId, pos, rot)

		if type(unitId) == "boolean" then
			unitId = not unitId
		end
	end

	file:close()
end
