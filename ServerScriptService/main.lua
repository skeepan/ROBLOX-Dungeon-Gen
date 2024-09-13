roomGenModule = require(game.ServerStorage.RoomGen)
DelaunayModule = require(game.ServerStorage.Util.Delaunay)
GraphModule = require(game.ServerStorage.Util.Graph)
RenderModule = require(game.ServerStorage.Render.Render)
config = game.ServerStorage.Configuration

p = 1

TILE_SIZE = config.Grid.TileSize.Value
GRID_SIZE = config.Grid.GridSize.Value
TOTAL_ROOMS = config.Room.TotalRooms.Value

ROOM_SZ_LOWER_LIM = config.Room.LowerLimit.Value -- 35
ROOM_SZ_UPPER_LIM = config.Room.UpperLimit.Value -- 50

--generate grid

function radialGradient(point,centre)
	local dist = math.sqrt((point[1]-centre[1])^2+(point[2]-centre[2])^2)
	return
end

function deepClone(tbl)
	local newtbl = {}
	for i, v in pairs(tbl) do
		newtbl[i] = type(v) == 'table' and deepClone(v) or v
	end
	return newtbl
end

function CreateWorldGrid()
	local wg = {}
	p=1
	for x = 1,GRID_SIZE do --gridSizeZ
		wg[x] = {}
		for z = 1,GRID_SIZE do --gridSizeX
			wg[x][z] = {Type = "Empty", Tile = "Empty"}
		end
	end
	return wg
end



--Function to add a room w/ RoomGrid of given dimensions and bite
function newRoom(tilePos, roomSizeX, roomSizeZ, Room)

	local roomNumber = #RoomList+1
	
	local roomFolder = Instance.new("Folder", workspace)
	roomFolder.Name = "Room"..p
	
	local roomGrid, roomCentre = roomGenModule.addRoom(tilePos, roomSizeX, roomSizeZ)
	
	for x,RowData in pairs(roomGrid) do
		
		for z,TileData in pairs(RowData) do
			if TileData.Type == "Tiled" then
				WorldGrid[tilePos.X+x][tilePos.Z+z] = {Type = TileData.Type, Room = roomNumber, Tile = TileData.Tile}
			end
		end
	end
	
	local RoomData = {
		Name = "Room"..p, 
		Grid = roomGrid, 
		Origin = tilePos, 
		Centre = roomCentre, 
		WallList = {}, 
		Connections = {}, 
		Parent = nil,
		Doors = {}
	}	-- This is a RoomData
	
	return RoomData
	
end

function generateRooms( worldgrid )
	local roomList = {}
	
	for i = 1, TOTAL_ROOMS do
		-- Generating rooms on the world grid.
		
		--Room dimensions
		local roomSizeX = math.random(ROOM_SZ_LOWER_LIM,ROOM_SZ_UPPER_LIM)
		local roomSizeZ = math.random(ROOM_SZ_LOWER_LIM,ROOM_SZ_UPPER_LIM)
		
		--Room top-left origin
		local roomOrigin = {
			X = math.random(2, #worldgrid - ROOM_SZ_UPPER_LIM-1),
			Z = math.random(2, #worldgrid[1] - ROOM_SZ_UPPER_LIM-1)
		}
		
		local generateNew = false --boolean set if previous generation attempt for room i failed.
		local spaceAvailable = false --boolean set if there is space available at the current position
	
		
		
		while worldgrid[roomOrigin.X][roomOrigin.Z].Type == "Tiled" or spaceAvailable == false do
			--print(WorldGrid[roomOrigin.X][roomOrigin.Y].Type, spaceAvailable)
			if worldgrid[roomOrigin.X][roomOrigin.Z].Type == "Tiled" or generateNew == true then
				--print("Creating room "..tostring(#RoomList+1).."at: ",roomOrigin," Dimensions:",roomSizeX,roomSizeZ)
				roomOrigin = {X = math.random(2,#worldgrid-ROOM_SZ_UPPER_LIM-1), Z = math.random(2,#worldgrid[1]-ROOM_SZ_UPPER_LIM-1)}
			end

			local spaceAvailable = true

			for x = -1,roomSizeX+1 do --Checking the World Grid
				for z = -1,roomSizeZ+1 do 
					--print("Checking Grid type for "..(roomOrigin.X+x),"/"..(roomOrigin.Y+z)..": "..WorldGrid[roomOrigin.X+x][roomOrigin.Y+z].Type)

					if roomOrigin.X~=0 and roomOrigin.Z~= 0 and worldgrid[roomOrigin.X+x][roomOrigin.Z+z].Type == "Tiled" then
						spaceAvailable = false
						generateNew = true
						--print("Error, Overlap Detected, generating new room...")
						break
					end
				end
			end
			--print(WorldGrid[roomOrigin.X][roomOrigin.Y].Type, spaceAvailable)
			if WorldGrid[roomOrigin.X][roomOrigin.Z].Type == "Empty" and spaceAvailable == true then break end
		end
		
		print("Creating room "..tostring(#roomList + 1).." at: ",roomOrigin.X,roomOrigin.Z," Dimensions:",roomSizeX,roomSizeZ, "Origin Type: "..WorldGrid[roomOrigin.X][roomOrigin.Z].Type)
		local roomData = newRoom(roomOrigin, roomSizeX,roomSizeZ, p)
		table.insert(roomList, roomData)
		p += 1
		
	end
	
	return roomList
end

ReadyToMakeWorld = true
DoorList = {}
PathList = {}
CorePathList = {}
WorldGrid = {}
RoomList = {}

while ReadyToMakeWorld do
	ReadyToMakeWorld = false
	WorldGrid = CreateWorldGrid()
	RoomList = generateRooms(WorldGrid)
	--print("WorldGrid = ", WorldGrid)
	
	PointList = {} -- pointList is a set of coordinates defining the points to be triangulated
	
	for i, room in ipairs(RoomList) do
		TriangulationCoord = {
			Vector2.new(room.Centre[1]+room.Origin.X, room.Centre[2]+room.Origin.Z) , 
			i
		}
		table.insert(PointList, TriangulationCoord)
	end
	
	print("PointList = ",PointList)
	triangulation = DelaunayModule.BowyerWatson(PointList) -- A set of Triangles
	
	print("Triangulation = ", triangulation)
	graph, CoordHash = GraphModule.makeGraph(triangulation, PointList)	
	
	RenderModule.buildTriangulation(triangulation)
	
	print("Graph = ",graph)
	path = GraphModule.Prims(graph, PointList)
	
	print("Path = ",path)
	RenderModule.buildEdges(path, PointList, CoordHash)
	
	for _, room in ipairs(RoomList) do
		list = roomGenModule.getWallList(room)
		room.WallList = list
	end
	
	
	
	
	
	for _, edge in ipairs(path) do --For each room in Path make a bridge to it from it's main node
	--print("Making door for room "..i)
		local room1 = RoomList[edge[1]] 
		local room2 = RoomList[edge[2]]
		
		room1Door, room2Door = roomGenModule.makeDoors(room1, room2)

		
		WorldGrid[room1Door[1]][room1Door[2]].Tile = "Door"
		WorldGrid[room2Door[1]][room2Door[2]].Tile = "Door"
		
		table.insert(room1.Doors, room1Door)
		table.insert(room2.Doors, room2Door)
		
		WorldGrid, PathList, CorePath = roomGenModule.aStar(room1, room2, WorldGrid, TILE_SIZE, PathList) --build bridge from room1 to room2
		WorldGrid = roomGenModule.generatePathBorder(PathList[#PathList], WorldGrid, TILE_SIZE)
		table.insert(CorePathList, CorePath)
	end
	
	print(RoomList)
	
	RenderModule.generateVoxelMap(WorldGrid)
	

	for i = 1,#CorePathList do
		roomGenModule.placeGate(CorePathList[i], WorldGrid, TILE_SIZE)
	end
	
	
	
	--print(Main_Path, Branches)
	for i = 1, #RoomList do
		roomGenModule.Courtyard(RoomList[i])
	end
	--[[
	Main_Path, Branches = roomGenModule.BFS(path[1] ,path[#path], RoomList) --change path[1] to a room with only one single path connecting
	
	Gates = {}
	for i = 1, math.random(1,#Branches) do
		
		function chooseBranch(Gates)
			newGate = Branches[math.random(1,#Branches)]
			if table.find(Gates,newGate) then
				chooseBranch(Gates)
			else return newGate
			end
		end
		
		newGate = chooseBranch(Gates)
	
		table.insert(Gates, newGate)
	end
	
	
	--print(Gates)
	]]
	--print("Rooms: ", RoomList)
	--function that finds the longest path 
	wait(12)
	for _, part in pairs(workspace.VoxelFolder:GetChildren()) do
		part:Destroy()
	end 
	table.clear(path)
	table.clear(RoomList)
	table.clear(PointList)
	table.clear(CorePathList)
	table.clear(PathList)

	ReadyToMakeWorld = true
end

--[[
Main_Path = {n1,n4,n5,n7,n8,n9,n14,n15}
]]





