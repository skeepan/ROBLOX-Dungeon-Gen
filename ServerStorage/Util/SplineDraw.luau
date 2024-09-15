local module = {}

TILE_SIZE = game.ServerStorage.Configuration.Grid.TileSize

function distance(xz1, xz2)
	return math.sqrt((xz1[1]-xz2[1])^2+(xz1[2]-xz2[2])^2)
end

function floorv3(v3)
	return Vector3.new(
		math.floor(v3.X),
		math.floor(v3.Y),
		math.floor(v3.Z))
end

function lerp(a, b, t)
	return a + (b - a) * t
end


function quadraticBezier(t, p0, p1, p2)
	local l1 = lerp(p0, p1, t)
	local l2 = lerp(p1, p2, t)
	local quad = lerp(l1, l2, t)

	return quad
end

function drawCurve(curvePointsArray)
	local curveTiles = {}
	
	local tempTileName = curvePointsArray[3].X.."/"..curvePointsArray[3].Z
	curveTiles[tempTileName] = workspace.VoxelFolder:FindFirstChild(tempTileName)
	tempTileName = curvePointsArray[1].X.."/"..curvePointsArray[1].Z
	curveTiles[tempTileName] = workspace.VoxelFolder:FindFirstChild(tempTileName)
	
	for t = 0, 1, 0.01 do

		local point = quadraticBezier(t, curvePointsArray[1], curvePointsArray[2], curvePointsArray[3])

		local tilePos = floorv3(point)
		local tileName = tilePos.X.."/"..tilePos.Z
		local tile = workspace.VoxelFolder:FindFirstChild(tileName)
		
		if tile then
			if not curveTiles[tileName] then
				curveTiles[tileName] = tile
			end
		end
		
	end
		
	for _,part in pairs(curveTiles) do
		if part.Material == Enum.Material.Grass and math.random(1,10)<11 then
			--part.CFrame = part.CFrame+Vector3.new(0, -TILE_SIZE/4,0)
			part.Color = Color3.new(0.769497, 0.828824, 0.566674)
			part.Material = Enum.Material.Slate
		end
	end
end

function findClosestGrassTile(room, no)
	
	local door = room.Doors[no]
	local closest = {math.huge , math.huge}
	for x = 1, #room.Grid do
		
		for z = 1, #room.Grid[x] do
			
			local t = {x+room.Origin.X, z+room.Origin.Z}
			
			if room.Grid[x][z].Tile == "Grass" and distance(door, t) < distance(door, closest) then
				closest = {x+room.Origin.X, z+room.Origin.Z}
				
			end
		end
	end
	print("Closest GrassTile to door "..room.Doors[no][1]..","..room.Doors[no][2].." is: "..closest[1]..","..closest[2])
	return closest
end


function module.draw1Paths(room)
	local door1 = findClosestGrassTile(room, 1)
	local door2 = findClosestGrassTile(room, 2)
	--local door1 = room.Doors[1]
	--local door2 = room.Doors[2]
	
	local doors = {
		Vector3.new(door1[1], 0, door1[2]),
		Vector3.new(door2[1], 0, door2[2]),
	}
	local ROOM_CENTRE = {room.Origin.X+room.Centre[1], room.Origin.Z+room.Centre[2]}
	local DOOR_CENTRE = (doors[1]+doors[2])/2 + Vector3.new(math.random(1,3), 0, math.random(1, 3))
	local DOOR_CENTRE = Vector3.new(ROOM_CENTRE[1], 0 , ROOM_CENTRE[2])
	-- Define spline control points for each curve
	local curve1Points = {doors[1], DOOR_CENTRE, doors[2]}

	drawCurve(curve1Points)

end

function module.draw3Paths(room)
	local ROOM_CENTRE = {room.Origin.X+room.Centre[1], room.Origin.Z+room.Centre[2]}
	local door1 = findClosestGrassTile(room, 1)
	local door2 = findClosestGrassTile(room, 2)
	local door3 = findClosestGrassTile(room, 3)
	--local door1 = room.Doors[1]
	--local door2 = room.Doors[2]
	--local door3 = room.Doors[3]
	local doors = {
		Vector3.new(door1[1], 0, door1[2]),
		Vector3.new(door2[1], 0, door2[2]),
		Vector3.new(door3[1], 0, door3[2]),
	}
	
	local DOOR_CENTRE = (doors[1]+doors[2]+doors[3])/3
	
	local DOOR_CENTRE = Vector3.new(ROOM_CENTRE[1], 0 , ROOM_CENTRE[2])

	-- Define spline control points for each curve
	local curve1Points = {doors[1], DOOR_CENTRE, doors[2]}
	local curve2Points = {doors[3], DOOR_CENTRE, quadraticBezier(math.random(10,30)/100, curve1Points[1], curve1Points[2], curve1Points[3])}
	local curve3Points = {
		quadraticBezier(math.random(50,70)/100, curve1Points[1], curve1Points[2], curve1Points[3]),
		DOOR_CENTRE,
		quadraticBezier(math.random(30,50)/100, curve2Points[1], curve2Points[2], curve2Points[3])
	}
	
	drawCurve(curve1Points)
	drawCurve(curve2Points)
	drawCurve(curve3Points)

end


return module
