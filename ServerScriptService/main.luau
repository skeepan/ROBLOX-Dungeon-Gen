roomGenModule = require(game.ServerStorage.RoomGen)
DelaunayModule = require(game.ServerStorage.Util.Delaunay)
GraphModule = require(game.ServerStorage.Util.Graph)
RenderModule = require(game.ServerStorage.Render.Render)

Types = require(game.ServerStorage.Util.Types)
config = game.ServerStorage.Configuration

p = 1

TILE_SIZE = config.Grid.TileSize.Value
GRID_SIZE = config.Grid.GridSize.Value
TOTAL_ROOMS = config.Room.TotalRooms.Value

ROOM_SZ_LOWER_LIM = config.Room.LowerLimit.Value -- 35
ROOM_SZ_UPPER_LIM = config.Room.UpperLimit.Value -- 50


--This structure defines a room. It is a table with the following fields:
type RoomData = {
	Name: string,
	Grid : Types.Grid, 
	Origin : Vector2, 
	Centre : Types.Coord, 
	WallList : { { Types.Coord } }, 
	Connections : {number}, 
	Parent : number | nil,
	Doors : { Types.Coord }
}

--This function clones a table.
function deepClone(tbl: {any}) : {any}
	local newtbl = {}
	for i, v in pairs(tbl) do
		newtbl[i] = type(v) == 'table' and deepClone(v) or v
	end
	return newtbl
end

--This function is called once and initializes the WorldGrid
function CreateWorldGrid() : Types.Grid
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

--Function to add a room w/ RoomGrid of given dimensions and bite size
function newRoom(tilePos : Vector2, roomSizeX : number, roomSizeZ: number, worldgrid : Types.Grid, roomlist : {RoomData})

	local roomNumber = #roomlist+1

	local roomFolder = Instance.new("Folder", workspace)
	roomFolder.Name = "Room"..p

	local roomGrid: Types.Grid, roomCentre : Types.Coord = roomGenModule.addRoom(tilePos, roomSizeX, roomSizeZ)

	for x,RowData in pairs(roomGrid) do

		for z,TileData in pairs(RowData) do
			if TileData.Type == "Tiled" then
				worldgrid[tilePos.X+x][tilePos.Z+z] = {Type = TileData.Type, Room = roomNumber, Tile = TileData.Tile}
			end
		end
	end

	local RoomData : RoomData = {
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

function generateRooms(worldgrid: Types.Grid): {RoomData}
	local roomList = {}

	for i = 1, TOTAL_ROOMS do
		local roomSizeX = math.random(ROOM_SZ_LOWER_LIM, ROOM_SZ_UPPER_LIM)
		local roomSizeZ = math.random(ROOM_SZ_LOWER_LIM, ROOM_SZ_UPPER_LIM)
		local roomOrigin : Types.Coord = {
			X = math.random(2, #worldgrid - ROOM_SZ_UPPER_LIM - 1),
			Z = math.random(2, #worldgrid[1] - ROOM_SZ_UPPER_LIM - 1)
		}

		local generateNew = false
		local spaceAvailable = false

		while worldgrid[roomOrigin.X][roomOrigin.Z].Type == "Tiled" or not spaceAvailable do
			if worldgrid[roomOrigin.X][roomOrigin.Z].Type == "Tiled" or generateNew then
				roomOrigin = {
					X = math.random(2, #worldgrid - ROOM_SZ_UPPER_LIM - 1),
					Z = math.random(2, #worldgrid[1] - ROOM_SZ_UPPER_LIM - 1)
				}
				generateNew = false
			end

			spaceAvailable = true

			-- Check the World Grid to ensure space is available
			for x = -1, roomSizeX + 1 do
				for z = -1, roomSizeZ + 1 do
					if worldgrid[roomOrigin.X + x] and worldgrid[roomOrigin.X + x][roomOrigin.Z + z] and 
						worldgrid[roomOrigin.X + x][roomOrigin.Z + z].Type == "Tiled" then
						spaceAvailable = false
						generateNew = true
						break
					end
				end
				if not spaceAvailable then break end
			end

			-- If space is available and the origin is valid, exit the loop
			if worldgrid[roomOrigin.X][roomOrigin.Z].Type == "Empty" and spaceAvailable then
				break
			end
		end

		print("Creating room " .. tostring(#roomList + 1) .. " at: ", roomOrigin.X, roomOrigin.Z, 
			" Dimensions:", roomSizeX, roomSizeZ, 
			" Origin Type: " .. worldgrid[roomOrigin.X][roomOrigin.Z].Type)

		local roomData = newRoom(roomOrigin, roomSizeX, roomSizeZ, worldgrid, roomList)
		table.insert(roomList, roomData)
	end

	return roomList
end



-- 
--================== Core map generation loop ======================= 

ReadyToMakeWorld = true
local DoorList: {Types.Coord} = {}
local PathList = {}
local CorePathList = {}
local WorldGrid : Types.Grid = {}
local RoomList : {RoomData} = {}


WorldGrid = CreateWorldGrid()
RoomList = generateRooms(WorldGrid)
--print("WorldGrid = ", WorldGrid)
	
local NodeList: {Types.Node} = {} -- NodeList is a set of coordinates defining the Nodes to be triangulated
	
--Fill out NodeList
for i, room in ipairs(RoomList) do
	TriangulationCoord = {
		Vector2.new(room.Centre[1]+room.Origin.X, room.Centre[2]+room.Origin.Z) ,
		i
	}
	table.insert(NodeList, TriangulationCoord)
end
print("NodeList = ",NodeList)
	
local triangulation: Types.Triangulation = DelaunayModule.BowyerWatson(NodeList) -- A set of Triangles
print("Triangulation = ", triangulation)
	
local graph: Types.Graph, CoordHash = GraphModule.makeGraph(triangulation, NodeList)	
print("Graph = ",graph)
	
RenderModule.buildTriangulation(triangulation)
	
local MinSpanningTree = GraphModule.Prims(graph, NodeList)
print("MinSpanningTree = ",MinSpanningTree)
	
RenderModule.buildEdges(MinSpanningTree, NodeList, CoordHash)
	
--Initialise the "'Wall List" for each room
for _, room in ipairs(RoomList) do
	list = roomGenModule.getWallList(room)
	room.WallList = list
end

--For each edge in MinSpanningTree make a bridge and doors between the two nodes
for _, edge in ipairs(MinSpanningTree) do 
--print("Making door for room "..i)
	local room1 = RoomList[edge[1]] 
	local room2 = RoomList[edge[2]]
	
	local room1Door: Types.Coord, room2Door: Types.Coord = roomGenModule.makeDoors(room1, room2)
	
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






