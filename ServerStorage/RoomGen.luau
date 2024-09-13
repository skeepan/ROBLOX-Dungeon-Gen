local roomGenModule = {}
local splineDraw = require(game.ServerStorage.Util.SplineDraw)
colors = {
	Brick = Color3.new(0.917647, 0.721569, 0.572549),
	Dirt = Color3.new(0.333333, 0.266667, 0.0235294),
	Grass = Color3.new(0.0509804, 0.74902, 0.458824)
}

groundMaterial = {"Dirt", "Grass"}

materials = {
	Brick = Enum.Material.Concrete,
	Dirt = Enum.Material.Grass,
	Grass = Enum.Material.Grass
}

shapes = { "circle", 
	"rectangle"
}

config = game.ServerStorage.Configuration

TILE_SIZE = config.Grid.TileSize.Value
GRID_SIZE = config.Grid.GridSize.Value
GRID_ORIGIN = TILE_SIZE * Vector3.new(0 - GRID_SIZE/2, 0 , 0 - GRID_SIZE/2)

function withinGrid(i, j, sizeX, sizeZ) 
	if i >= 1 and i <= sizeX and j >= 1 and j <= sizeZ then
		return true
	else return false
	end
end

function findTileGrid(needle,grid, bool) --if bool is true, then the result will only return boolean value
	local found = false
	for x,row in pairs(grid) do
		for z,tile in pairs(row) do
			print(needle, tile)
			if tile[1] == needle[1] and tile[2] == needle[2] then
				found = true
				if bool == true then return found else
					return tile end
			end
		end
	end	
	return found
end

function findTileList(needle,list, bool) --if bool is true, then the result will only return boolean value
	local found = false
	for z,tile in pairs(list) do
		if tile[1] == needle[1] and tile[2] == needle[2] then
			found = true
			if bool == true then return found else
				return tile end
		end
	end
	return found
end

function deepClone(tbl)
	local newtbl = {}
	for i, v in pairs(tbl) do
		newtbl[i] = type(v) == 'table' and deepClone(v) or v
	end
	return newtbl
end

function getNeighbours(tile, grid) 

	local tileNeighbours = {}
	local x,z = tile[1],tile[2]

	for i = x-1,x+1 do
		table.insert(tileNeighbours, {})
		local row = tileNeighbours[#tileNeighbours]
		for j = z-1,z+1 do
			local tempTile = {i,j, Tile = grid[i][j].Tile}
			if withinGrid(i,j, #grid, #grid[1]) then
				table.insert(row, tempTile)
			else
				local tempTile = {i,j, Tile = grid[i][j].Tile}
				table.insert(row, tempTile)
			end
		end
	end

	return tileNeighbours

end

function getAdjNeighbours(tile, grid) 

	local adjNeighbours = {}
	local tileNeighbours = getNeighbours(tile, grid)

	table.insert(adjNeighbours, tileNeighbours[2][1])
	table.insert(adjNeighbours, tileNeighbours[1][2])
	table.insert(adjNeighbours, tileNeighbours[2][3])
	table.insert(adjNeighbours, tileNeighbours[3][2])

	return adjNeighbours

end

function roomGenModule.addRoom(tilePos, roomSizeX, roomSizeZ, roomNo)
	local roomGrid = {}

	for x=1,roomSizeX do
		roomGrid[x] = {}
		for z = 1,roomSizeZ do
			roomGrid[x][z] = {Type = "Tiled", Tile = "debug", Room = roomNo}
			if x == 1 or x == roomSizeX or z == 1 or z == roomSizeZ then
				roomGrid[x][z].Tile = "Wall"
				--elseif x == 2 or x == roomSizeX-1 or z == 2 or z == roomSizeZ-1 then
				--roomGrid[x][z].Tile = "Border"
			else
				roomGrid[x][z].Tile = "Grass"
			end
		end 
	end

	local longerDimension = roomSizeX
	local shorterDimension = roomSizeZ
	if roomSizeZ > longerDimension then longerDimension = roomSizeZ shorterDimension = roomSizeX end

	local bite = shapes[math.random(#shapes)]

	if bite == "circle" or bite == "rectangle" then

		local innerRadius = shorterDimension
		local outerRadius = longerDimension*3/2
		local biteRadius = longerDimension

		local biteP = {math.random(math.floor(-longerDimension/2),math.floor(longerDimension/2+roomSizeX)),
			math.random(math.floor(-longerDimension/2),math.floor(longerDimension/2+roomSizeX))
		}

		while math.sqrt((biteP[1]-roomSizeX/2)^2+(biteP[2]-roomSizeZ/2)^2)<innerRadius do
			biteP = {math.random(math.floor(-longerDimension/2),math.floor(longerDimension/2+roomSizeX)),
				math.random(math.floor(-longerDimension/2),math.floor(longerDimension/2+roomSizeX))
			}
		end 


		for x, tileRow in pairs(roomGrid) do
			for z, tile in pairs(tileRow) do
				if math.sqrt((biteP[1]-x)^2+(biteP[2]-z)^2)<biteRadius then --Turning bite into empty tile
					roomGrid[x][z].Type = "Empty"
					tile.Type = "Empty"
					tile.Tile = "Empty"
				end
			end
		end
	end

	if bite == "circle" or bite == "rectangle" then


		local biteSize = {

			math.random(math.floor(3/4*longerDimension),math.floor(longerDimension-4)),
			math.random(math.floor(3/4*longerDimension),math.floor(longerDimension-4))

		}

		local biteOrigin = {

			math.random(math.floor(-biteSize[1]/2),math.floor(roomSizeX+biteSize[1]/2)),
			math.random(math.floor(-biteSize[2]/2),math.floor(roomSizeZ+biteSize[2]/2))
		}

		for x = 1, biteSize[1] do
			for z = 1, biteSize[2] do
				if biteOrigin[1]+x > 0 and biteOrigin[1]+x <= roomSizeX then
					if biteOrigin[2]+z > 0 and biteOrigin[2]+z <= roomSizeZ then
						roomGrid[biteOrigin[1]+x][biteOrigin[2]+z].Type = "Empty"
						roomGrid[biteOrigin[1]+x][biteOrigin[2]+z].Tile = "Empty"
					end
				end

			end
		end

	end

	local newWalls = {}

	for x, tileRow in pairs(roomGrid) do
		for z, tile in pairs(tileRow) do
			if tile.Type == "Empty" then
				for i = x-1,x+1 do
					for j = z-1,z+1 do

						if withinGrid(i,j, #roomGrid, #tileRow) and roomGrid[i][j].Type ~= "Empty" then	
							table.insert(newWalls, {x,z})
							--any time Z == 1, it does not get through to here. this means for all Z==1, roomGrid[i][1], adjTileDoesNotExist == true
						end
					end
				end
			end
		end
	end

	for i,v in pairs(newWalls) do
		roomGrid[v[1]][v[2]].Type = "Tiled"
		roomGrid[v[1]][v[2]].Tile = "Wall"
	end

	local newBorders = {}

	local function createBorders()
		for x, tileRow in pairs(roomGrid) do
			for z, tile in pairs(tileRow) do
				if tile.Tile == "Grass" then
					for i = x-1,x+1 do

						for j = z-1,z+1 do

							if withinGrid(i,j, #roomGrid, #tileRow) and roomGrid[i][j].Tile ~= "Grass" then	
								table.insert(newBorders, {x,z})
								--print(i,j,floorTiles[i][j])
							end
						end
					end
				end
			end
		end
		for i,v in pairs(newBorders) do
			roomGrid[v[1]][v[2]].Type = "Tiled"
			roomGrid[v[1]][v[2]].Tile = "Border"
		end
		table.clear(newBorders)
	end

	createBorders()
	createBorders()

	local totalX = 0
	local totalZ = 0
	local noOfTiled = 0
	for x,tileRow in pairs(roomGrid) do
		for z,tile in pairs(tileRow) do
			if tile.Tile == "Grass" or tile.Tile == "Border" then
				noOfTiled += 1
				totalX += x
				totalZ += z
				--print("X == ",totalX, "+x = "..x)
				--print("Z == ",totalZ, "+z = "..z)
			end	
		end

	end
	if noOfTiled == 0 then
		print("NaN alert", tilePos,roomNo,roomGrid)
		totalX =  tilePos.X
		totalZ = tilePos.Z
		noOfTiled = 1
	end
	local meanX = totalX/noOfTiled
	local meanZ = totalZ/noOfTiled

	local roomCentre = {math.floor(meanX),math.floor(meanZ)}
	if noOfTiled ~= 1 then	roomGrid[roomCentre[1]][roomCentre[2]].Tile = "Centre" end


	return roomGrid, roomCentre
end

function roomGenModule.getWallList(room1)

	local function GetWallList(room1)
		local WallList1 = {}
		local grid1 = room1.Grid

		for x, row in pairs(grid1) do
			for z,tile in pairs(row) do
				if tile.Tile == "Wall" then
					local tileNeighbours = {}

					for i = x-1,x+1 do
						-- checking wall neighbours

						table.insert(tileNeighbours, {})
						local neighbourRow = tileNeighbours[#tileNeighbours]
						for j = z-1,z+1 do

							if withinGrid(i,j, #grid1, #row) and grid1[i][j].Tile == "Wall"  then
								-- if the neighbour is within the bounds of the room then
								-- if its is a wall, add it to the neighbour list
								table.insert(neighbourRow, {i,j, Tile = "Wall"})
							else
								table.insert(neighbourRow, {i,j, Tile = "Not Wall"})
							end
						end
					end

					if ((tileNeighbours[1][2].Tile == "Wall" or tileNeighbours[3][2].Tile == "Wall") and not ((tileNeighbours[2][3].Tile == "Wall" or tileNeighbours[2][1].Tile == "Wall"))) or 
						((tileNeighbours[2][3].Tile == "Wall" or tileNeighbours[2][1].Tile == "Wall") and not ((tileNeighbours[1][2].Tile == "Wall" or tileNeighbours[3][2].Tile == "Wall"))) then
						table.insert(WallList1, {x,z})
					end
					--print(WallList1)
				end
			end
		end
		--print("WallTiles = ",WallList1)

		local EdgeList = {}
		for w,wall in pairs(WallList1) do

			local hasAdjacentWall = false
			local adjacentWall --smarter to store the constant x/y and then check for all
			for o,otherWall in pairs(WallList1) do
				if ((otherWall[1] == wall[1]+1 or otherWall[1] == wall[1]-1) and (otherWall[2] == wall[2])) or -- check if the otherWall in the list is adjacent 
					((otherWall[2] == wall[2]+1 or otherWall[2] == wall[2]-1) and  (otherWall[1] == wall[1])) then

					adjacentWall = {otherWall[1],otherWall[2]}
					--print("Wall: ",wall,"Adjacent= ",adjacentWall)
					hasAdjacentWall = true
					break
				end
			end

			if w==1 then
				table.insert(EdgeList, {wall})
				--print("starterEdgeList =", EdgeList)
			end

			local hasAssociatedEdge = false
			if hasAdjacentWall == true then
				--print("wall/adjWall",wall,adjacentWall)
				for e,edge in pairs(EdgeList) do --check if our OtherWall has an associated edge, if not, create a new edge and add our current wall to it.
					for _,eWall in pairs(edge) do
						--print("wall/adjWall",eWall)
						if (adjacentWall[1] == eWall[1] and adjacentWall[2] == eWall[2]) then
							table.insert(edge,wall)
							hasAssociatedEdge = true
							--print("EdgeList =", EdgeList)
							break
						end
					end
				end

				if hasAssociatedEdge == false and w~=1 then
					table.insert(EdgeList, {wall})

				end

			elseif hasAdjacentWall == false and w~=1 then	
				table.insert(EdgeList, {wall})
				--	print("wall has no adjacentwalls",wall)
			end


		end
		return EdgeList	
	end

	local room1Walls = GetWallList(room1)

	-- Converting to WorldGrid Coordinates from relative coordinates
	for _,edge in pairs(room1Walls) do
		for t,tile in pairs(edge) do
			tile[1] += room1.Origin.X
			tile[2] += room1.Origin.Z
		end

	end

	return room1Walls

end

function roomGenModule.makeDoors(room1, room2)
	local function getMidPoints(room, target)
		local midPoints = {}
		for i,wallSet in ipairs(room.WallList) do
			local xT,yT = 0,0
			for w,wall in ipairs(wallSet) do
				xT += wall[1]
				yT += wall[2]
			end
			midPoints[#midPoints+1] = {xT/#wallSet, yT/#wallSet}
		end

		local closest, distance = nil, 1000

		for _,point in ipairs(midPoints) do
			local pDist = math.sqrt( (point[1]-target[1])^2 + (point[2]-target[2])^2 ) 
			point[#point+1] = pDist
			if pDist < distance then
				distance = pDist
				closest = point
			end

		end
		closest = midPoints[math.random(1, #midPoints)] --- FOR INTERESTING DOORS
		--print("Chose Door at ",{math.floor(closest[1]),math.floor(closest[2])}, midPoints, room.WallList, tostring(target[1]),tostring(target[2]) ) -- currently its just choosing the last path on the list
		return {math.floor(closest[1]), math.floor(closest[2])}  
	end

	local MP1 = getMidPoints(room1, {room2.Origin.X+room2.Centre[1],room2.Origin.Z+room2.Centre[2]})
	local MP2 = getMidPoints(room2, {MP1[1],MP1[2]})

	return {MP1[1],MP1[2]}, {MP2[1],MP2[2]}
end

function roomGenModule.aStar(room1,room2, worldGrid, TILE_SIZE, pathList)

	local function getMidPoints(room, target)
		local midPoints = {}
		for i, wallSet in ipairs(room.WallList) do
			local xT,yT = 0,0
			for w,wall in ipairs(wallSet) do
				xT += wall[1]
				yT += wall[2]
			end
			midPoints[#midPoints+1] = {xT/#wallSet, yT/#wallSet}
		end

		local closest, distance = nil, 1000

		for _,point in ipairs(midPoints) do
			local pDist = math.sqrt( (point[1]-target[1])^2 + (point[2]-target[2])^2 ) 
			point[#point+1] = pDist
			if pDist < distance then
				distance = pDist
				closest = point
			end

		end
		--closest = midPoints[math.random(1,#midPoints)]
		--print("Chose Door at ",{math.floor(closest[1]),math.floor(closest[2])}, midPoints, room.WallList, tostring(target[1]),tostring(target[2]) ) -- currently its just choosing the last path on the list
		return {math.floor(closest[1]),math.floor(closest[2])}  
	end

	local MP1  = getMidPoints(room1, {room2.Origin.X+room2.Centre[1],room2.Origin.Z+room2.Centre[2]})
	local MP2 = getMidPoints(room2, {MP1[1],MP1[2]})

	local startNode, endNode = MP1,MP2

	--Creating Start and End nodes
	local function getStartEndNode(MidPoint)
		local MPNeighbs = getNeighbours(MidPoint, worldGrid) -- returns {x,z, tile = ""}
		local StartEndNode = nil
		if MPNeighbs[1][2].Tile == "Empty" or MPNeighbs[1][2].Tile == "Door" or string.find(MPNeighbs[1][2].Tile,"Path") or MPNeighbs[1][2].Tile == "PBorder" then StartEndNode = MPNeighbs[1][2] end
		if MPNeighbs[2][1].Tile == "Empty" or MPNeighbs[2][1].Tile == "Door" or string.find(MPNeighbs[2][1].Tile,"Path") or MPNeighbs[2][1].Tile == "PBorder" then StartEndNode = MPNeighbs[2][1] end
		if MPNeighbs[2][3].Tile == "Empty" or MPNeighbs[2][3].Tile == "Door" or string.find(MPNeighbs[2][3].Tile,"Path") or MPNeighbs[2][3].Tile == "PBorder" then StartEndNode = MPNeighbs[2][3] end
		if MPNeighbs[3][2].Tile == "Empty" or MPNeighbs[3][2].Tile == "Door" or string.find(MPNeighbs[3][2].Tile,"Path") or MPNeighbs[3][2].Tile == "PBorder" then StartEndNode = MPNeighbs[3][2] end
		return StartEndNode
	end

	startNode = getStartEndNode(MP1)
	endNode = getStartEndNode(MP2)

	local function fCost(tile, start, goal, parent, otherPathHasBeenUsed)

		local gCost = math.abs(tile[1] - start[1]) + math.abs(tile[2]-start[2])
		--[[local gCost 
		if tile[1] == start[1] and tile[2] == start[2] then gCost = 0 
		else gCost = parent[5] + 1
		end]]

		local hCost = math.abs(goal[1] - tile[1]) + math.abs(goal[2]-tile[2])
		if string.find(worldGrid[tile[1]][tile[2]].Tile,"Path") and not (parent == nil) then
			gCost = parent[5]+0.9
			hCost = parent[4]-0.9
		elseif string.find(worldGrid[tile[1]][tile[2]].Tile,"PBorder") and otherPathHasBeenUsed == true then
			gCost = parent[5]-100
			hCost = parent[4]+100
		end
		return hCost+gCost, hCost,gCost
	end

	--print("Starting and Ending at :",startNode, endNode)

	local openCloseWorld = {}
	--This is to track which tiles are in an open or close list easily without having to perform search loops
	for x, row in pairs(worldGrid) do
		openCloseWorld[x] = {}
		for z, tile in pairs(row) do
			openCloseWorld[x][z] = "Free"
		end
	end


	local closed = {}
	local open = {}

	local fC,hC,gC = fCost(startNode,startNode,endNode)
	open[1] = {startNode[1], startNode[2],fC,hC,gC, parent = nil}

	--workspace.VoxelFolder[startNode[1].."/"..startNode[2]].Color = Color3.new(0.380392, 0.627451, 1)
	--workspace.VoxelFolder[endNode[1].."/"..endNode[2]].Color = Color3.new(0.380392, 0.627451, 1)

	local path = nil
	local otherPathHasBeenUsed = false
	local function astar(tile)

		--print("Running on tile:"..tile[1].."/"..tile[2])

		if tile[1] == endNode[1] and tile[2] == endNode[2] then path = tile --print("path found", path) 
			return end 
		local chosenTile = nil
		local neighbours = {}
		if string.find(worldGrid[tile[1]][tile[2]].Tile,"Path") then
			otherPathHasBeenUsed = true
		end
		table.insert(closed, tile)
		openCloseWorld[tile[1]][tile[2]] = "Closed"

		--workspace.VoxelFolder[tile[1].."/"..tile[2]].Color = Color3.new(0.666667, 0, 0)

		for index,openT in pairs(open) do
			if openT[1] == tile[1] and openT[2] == tile[2] then table.remove(open,index) end
		end
		--find neighbours of the currentTile

		local currentNeighbs = getNeighbours(tile, worldGrid) -- returns {x,z, tile = ""}

		if currentNeighbs[1][2].Tile == "Empty" or currentNeighbs[1][2].Tile == "Door" or string.find(currentNeighbs[1][2].Tile,"Path") or currentNeighbs[1][2].Tile == "PBorder" then neighbours[#neighbours+1] = {currentNeighbs[1][2][1], currentNeighbs[1][2][2]} end
		if currentNeighbs[2][1].Tile == "Empty" or currentNeighbs[2][1].Tile == "Door" or string.find(currentNeighbs[2][1].Tile,"Path") or currentNeighbs[2][1].Tile == "PBorder" then neighbours[#neighbours+1] = {currentNeighbs[2][1][1], currentNeighbs[2][1][2]} end
		if currentNeighbs[2][3].Tile == "Empty" or currentNeighbs[2][3].Tile == "Door" or string.find(currentNeighbs[2][3].Tile,"Path") or currentNeighbs[2][3].Tile == "PBorder" then neighbours[#neighbours+1] = {currentNeighbs[2][3][1], currentNeighbs[2][3][2]} end
		if currentNeighbs[3][2].Tile == "Empty" or currentNeighbs[3][2].Tile == "Door" or string.find(currentNeighbs[3][2].Tile,"Path") or currentNeighbs[3][2].Tile == "PBorder" then neighbours[#neighbours+1] = {currentNeighbs[3][2][1], currentNeighbs[3][2][2]} end

		--print("Neighbours of current tile = ",neighbours) -- it works! yay! 4:29pm 23/8/22			

		for n,neighbour in pairs(neighbours) do
			--hCost = distance away from the end
			--gCost = distance away from the start

			local fCost, hCost, gCost = fCost(neighbour, startNode, endNode, tile,otherPathHasBeenUsed)

			if gCost<tile[5] and findTileList(neighbour,closed,true) == true and openCloseWorld[neighbour[1]][neighbour[2]] == "Closed" then -- if neighbour is closed and is closer to the start, set the parent of the our current tile to the closed neighbour
				local neighbInClosed = findTileList(neighbour,closed,false) 
				neighbInClosed[3] = fCost 
				neighbInClosed[4] = hCost
				neighbInClosed[5] = gCost
				tile.parent = neighbInClosed
			elseif openCloseWorld[neighbour[1]][neighbour[2]] == "Open" then

				--if neighbour is in the open list and it is further from the start than current, then current becomes the parent
				local neighbInOpen = findTileList(neighbour,open,false) 
				if tile[5]<gCost then
					neighbInOpen[3] = fCost 
					neighbInOpen[4] = hCost
					neighbInOpen[5] = gCost
					neighbInOpen.parent = tile
				end

			elseif openCloseWorld[neighbour[1]][neighbour[2]] == "Free" then
				openCloseWorld[neighbour[1]][neighbour[2]] = "Open"
				local data = {neighbour[1], neighbour[2],fCost,hCost,gCost, parent = tile}
				table.insert(open, data)
				--workspace.VoxelFolder[neighbour[1].."/"..neighbour[2]].Color = Color3.new(0, 1, 0.498039)
			end


		end

		--print("Open list: ",open)
		local lowestfCost = 1000000
		local currentgCost = 0
		local currenthCost = 1000000
		-- choosing the tile with the lowest fcost in Open
		for o,openTile in ipairs(open) do 
			local fCost = openTile[3]
			local hCost = openTile[4]
			local gCost = openTile[5]
			if fCost<lowestfCost and (worldGrid[openTile[1]][openTile[2]].Tile == "Empty" or string.find(worldGrid[openTile[1]][openTile[2]].Tile,"Path") or worldGrid[openTile[1]][openTile[2]].Tile == "PBorder" ) then 
				lowestfCost = fCost 
				currenthCost = hCost
				currentgCost = gCost
				chosenTile = openTile 
			elseif fCost == lowestfCost and (worldGrid[openTile[1]][openTile[2]].Tile == "Empty" or string.find(worldGrid[openTile[1]][openTile[2]].Tile,"Path") or worldGrid[openTile[1]][openTile[2]].Tile == "PBorder" ) and hCost<currenthCost then
				currenthCost = hCost
				currentgCost = gCost
				chosenTile = openTile 
			elseif fCost == lowestfCost and hCost==currenthCost and (worldGrid[openTile[1]][openTile[2]].Tile == "Empty" or string.find(worldGrid[openTile[1]][openTile[2]].Tile,"Path") or worldGrid[openTile[1]][openTile[2]].Tile == "PBorder" ) and gCost>currentgCost then
				currentgCost = gCost
				chosenTile = openTile 
			end

		end

		chosenTile.parent = tile

		--print("Chose: "..chosenTile[1].."/"..chosenTile[2])
		astar(chosenTile)
	end

	astar(open[1])
	local newPath = {}
	local corePath = {}
	local function buildPath(endTile, startTile)

		local currentTile = endTile

		--Visualisation
		--for i,ctile in pairs(closed) do
		--workspace.VoxelFolder[ctile[1].."/"..ctile[2]].Color = Color3.fromRGB(163, 162, 165)
		--end
		--for i,otile in pairs(open) do
		--workspace.VoxelFolder[otile[1].."/"..otile[2]].Color = Color3.fromRGB(163, 162, 165)
		--end

		local pathColor = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
		while currentTile ~= nil do
			table.insert(corePath, currentTile)
			--wait()
			local adjBorders = {}
			--workspace.VoxelFolder[currentTile[1].."/"..currentTile[2]].Color = Color3.new(1, 1, 0)
			for i = currentTile[1]-1,currentTile[1]+1 do
				for j = currentTile[2]-1,currentTile[2]+1 do

					local connectsToAPath = false
					local adjTileDoesNotExist = false

					--print("x/z = "..x,z)
					if withinGrid(i,j, #worldGrid[1], #worldGrid) then
						if worldGrid[i][j].Tile == "Empty" then

							local newTile = workspace.Replacements["Replacement Bevel2"]:Clone()
							newTile.Size = Vector3.new(TILE_SIZE,TILE_SIZE,TILE_SIZE)
							newTile.CFrame = CFrame.new(TILE_SIZE*i,1,TILE_SIZE*j) + GRID_ORIGIN
							newTile.Anchored = true
							--newTile.CanCollide = false
							newTile.Name = i.."/"..j
							newTile.Parent = workspace.VoxelFolder
							workspace.VoxelFolder[i.."/"..j].Color = pathColor --Color3.fromRGB(172, 133, 107)	
							workspace.VoxelFolder[i.."/"..j].Material = "Concrete"
							worldGrid[i][j].Tile = "Path"..#pathList+1
							table.insert(newPath, {i,j})
						elseif worldGrid[i][j].Tile == "PBorder" then
							print("Detected Pborder neighbour")
							table.insert(adjBorders, {i,j})
						elseif string.find(worldGrid[i][j].Tile,"Path") and not (worldGrid[i][j].Tile == "Path"..#pathList+1) and connectsToAPath == false then
							connectsToAPath = true
							-- This is literally detecting
						end

					end
					if connectsToAPath == true then

						for _,PBorder in adjBorders do
							local oldTile = workspace.VoxelFolder[PBorder[1].."/"..PBorder[2]]
							oldTile.Size = Vector3.new(TILE_SIZE,TILE_SIZE,TILE_SIZE)
							oldTile.Color = pathColor
							worldGrid[PBorder[1]][PBorder[2]].Tile = "Path"..#pathList+1
							table.insert(newPath, {PBorder[1],PBorder[2]})
						end
					end
				end
			end


			currentTile = currentTile.parent

		end

		table.insert(pathList,newPath)

	end

	buildPath(path, startNode)
	return worldGrid, pathList, corePath
end

function roomGenModule.generatePathBorder(pathGrid, worldGrid, TILE_SIZE)

	for _, currentTile in pairs(pathGrid) do


		for i = currentTile[1]-1,currentTile[1]+1 do

			for j = currentTile[2]-1,currentTile[2]+1 do
				if withinGrid(i,j, #worldGrid[1], #worldGrid) and worldGrid[i][j].Tile == "Empty" then

					local newTile = workspace.Replacements["Replacement Bevel2"]:Clone()
					newTile.Size = Vector3.new(TILE_SIZE,TILE_SIZE*2,TILE_SIZE)
					newTile.CFrame = CFrame.new(TILE_SIZE*i,1,TILE_SIZE*j) + GRID_ORIGIN
					newTile.Anchored = true
					--newTile.CanCollide = false
					newTile.Name = i.."/"..j
					newTile.Parent = workspace.VoxelFolder
					workspace.VoxelFolder[i.."/"..j].Color = Color3.fromRGB(0, 0, 0)	
					workspace.VoxelFolder[i.."/"..j].Material = "Concrete"

					worldGrid[i][j].Tile = "PBorder"
				end
			end
		end

	end

	return worldGrid
end

function roomGenModule.placeGate(path, worldGrid, TILE_SIZE)
	local gateLocations = {}

	for _,core in pairs(path) do
		local nextToDoor = false
		local direction = "none"
		local adjNeighbours = getAdjNeighbours(core,worldGrid)

		for _,neighb in adjNeighbours do
			if neighb.Tile == "Door" then nextToDoor = true break end 
		end

		if nextToDoor ~= true then
			local adjCores = {}
			for _,otherCore in path do
				if ((otherCore[1] == core[1]+1 or otherCore[1] == core[1]-1) and (otherCore[2] == core[2])) and (direction == "none" or direction == "Z") then
					direction = "Z"
					table.insert(adjCores, otherCore)
				elseif ((otherCore[2] == core[2]+1 or otherCore[2] == core[2]-1) and  (otherCore[1] == core[1])) and (direction == "none" or direction == "X") then
					direction = "X"
					table.insert(adjCores, otherCore)
				end
			end

			if direction ~= "none" and #adjCores >= 2 then
				if direction == "X" and not (string.find(worldGrid[core[1]+2][core[2]].Tile, "Path") or string.find(worldGrid[core[1]-2][core[2]].Tile, "Path")) and not (string.find(worldGrid[core[1]+2][core[2]].Tile, "Door") or string.find(worldGrid[core[1]-2][core[2]].Tile, "Door")) then
					--print(core,worldGrid[core[1]+2][core[2]].Tile, worldGrid[core[1]-2][core[2]].Tile)
					table.insert(gateLocations, {core,"X"})
				elseif direction == "Z" and not (string.find(worldGrid[core[1]][core[2]+2].Tile, "Path") or string.find(worldGrid[core[1]][core[2]-2].Tile, "Path")) and not (string.find(worldGrid[core[1]][core[2]+2].Tile, "Door") or string.find(worldGrid[core[1]][core[2]-2].Tile, "Door")) then
					table.insert(gateLocations, {core,"Z"})
				end


			end

		end

	end

	for _,location in gateLocations do
		workspace.VoxelFolder[location[1][1].."/"..location[1][2]].Color = Color3.fromRGB(255, 255, 255)
		workspace.VoxelFolder[location[1][1].."/"..location[1][2]].Size = Vector3.new(TILE_SIZE,TILE_SIZE,TILE_SIZE)
	end
	return worldGrid
end

function roomGenModule.BFS(nStart, nEnd, roomList)

	local visited = {}
	local queue = {}
	local qIndex = 0
	local current = nEnd --Current is set to the room_number eg. 3 or 14

	while current ~= nStart.Node[3] do
		--print(current,visited,queue)
		for _,node in pairs(roomList[current].Connections) do
			if not (table.find(visited,node)) then
				queue[#queue+1] = node
				roomList[node].Parent = current
			end

		end

		qIndex += 1
		visited[#visited+1] = current
		current = queue[qIndex]

	end


	local Main_Path = {}
	local Branches = {}
	local pointer = current
	while pointer ~= nEnd.Node[3] do
		Main_Path[#Main_Path+1] = roomList[pointer].Parent
		pointer = roomList[pointer].Parent
	end


	for _,node in Main_Path do
		if #roomList[node].Connections > 2 then
			for _,c in roomList[node].Connections do
				if not (table.find(Branches,node)) then
					Branches[#Branches+1] = node
				end
			end

		end
	end

	return Main_Path, Branches
end
--add a flood fill function
function roomGenModule.Courtyard(room)

	--Basically, we need to find the GRASS tiles which are closest to the doors, 
	--we could ALSO find the further corner grass tile to use as a middle point in the bezier
	print("Drawing paths for "..room.Name)
	if #room.Doors == 3 then splineDraw.draw3Paths(room) end
	if #room.Doors == 2 then splineDraw.draw1Paths(room) end
end

return roomGenModule
