local module = {}

TILE_SIZE = game.ServerStorage.Configuration.Grid.TileSize.Value
GRID_SIZE = game.ServerStorage.Configuration.Grid.GridSize.Value
GRID_ORIGIN = TILE_SIZE*Vector3.new(0 - GRID_SIZE/2, 0 , 0 - GRID_SIZE/2)
	
function module.generateVoxelMap(worldgrid)
	local Voxels = workspace.VoxelFolder:GetChildren()
	local random = math.random(0,10000)
	for x,row in pairs(worldgrid) do
		for z,tile in pairs(row) do
			--[[if tile.Type == "Empty" then
				local NewTile = Instance.new("Part",workspace.VoxelFolder)
				NewTile.CFrame = CFrame.new(TILE_SIZE*x,1,TILE_SIZE*z)
				NewTile.Anchored = true
				NewTile.Size = Vector3.new(TILE_SIZE,1,TILE_SIZE)
				NewTile.Name = x.."/"..z
				NewTile.CanCollide = false
			end]]
			if tile.Type == "Tiled" then 
				local NewTile = workspace.Replacements["Replacement Bevel2"]:Clone()
				NewTile.Name = x.."/"..z
				NewTile.Parent = workspace.VoxelFolder
				NewTile.Anchored = true
				NewTile.Size = Vector3.new(TILE_SIZE, 1, TILE_SIZE)
				--NewTile.CanCollide = false
				NewTile.CFrame = CFrame.new(TILE_SIZE * x,1,TILE_SIZE * z) + GRID_ORIGIN
				if tile.Tile == "Grass" then
					--NewTile.Color = Color3.new(0.513725, 1, 0.458824)
					local scale = 5
					local noise = math.noise((x + random) / scale, (z + random) / scale, 5346) / 5
					--	NewTile.Color = Color3.new(0.0509804, 0.74902, 0.458824)
					NewTile.Color = Color3.fromHSV(0.430722, 0.931945, 0.74902+noise)
					NewTile.CFrame = (NewTile.CFrame+Vector3.new(0,2*noise,0))
					NewTile.Material = "Grass"
				elseif tile.Tile == "Wall" then
					NewTile.Size = Vector3.new(TILE_SIZE, TILE_SIZE * 2.5, TILE_SIZE)
					NewTile.Material = "Concrete"
					NewTile.CFrame = NewTile.CFrame*CFrame.new(0, TILE_SIZE*2.5/2, 0)
					NewTile.Color = Color3.new(0.917647, 0.721569, 0.572549)
				elseif tile.Tile == "Border" then
					NewTile.Material = "Concrete"
					NewTile.Color = Color3.new(0.67451, 0.52549, 0.419608)
				elseif tile.Tile == "Bite" then
					NewTile.Color = Color3.new(0.478431, 0.156863, 0.478431)
				elseif tile.Tile == "Centre" then
					NewTile.Color = Color3.new(0, 1, 0.917647)
				elseif tile.Tile == "Door" then
					NewTile.Color = Color3.new(0.67451, 0.52549, 0.419608)
				end

			end 

		end
	end


end

function module.buildEdges(path, point_list, coord_hash)
	
	for i, point in point_list do
		local vec_p : Vector2 = point[1]
		local NewTile : Part = Instance.new("Part")
		
		NewTile.Anchored = true
		NewTile.CanCollide = false
		NewTile.Color = Color3.new(0, 1, 0)
		NewTile.Name = vec_p.X.."/"..vec_p.Y.."Node"
		
		NewTile.Size = Vector3.new(TILE_SIZE/2, TILE_SIZE/2, TILE_SIZE/2)
		
		NewTile.CFrame = CFrame.new(
			TILE_SIZE * vec_p.X,
			2, 
			TILE_SIZE * vec_p.Y
		) + GRID_ORIGIN
		
		NewTile.Parent = workspace.VoxelFolder
		
		local gui = Instance.new("BillboardGui", workspace.VoxelFolder[vec_p.X.."/"..vec_p.Y.."Node"])
		gui.AlwaysOnTop = true
		gui.Size = UDim2.new(4,0,1,0)
		
		local textobj = Instance.new("TextLabel", gui)
		textobj.Size = UDim2.new(1,0,1,0)
		textobj.Text = tostring(i)
		
	end
	
	for _, edge in ipairs(path) do
		local vec_v1 : Vector2 = point_list[edge[1]][1]
		local vec_v2 : Vector2 = point_list[edge[2]][1]
		local NewConnector = Instance.new("Part")
		
		NewConnector.Transparency = 0.5
		NewConnector.Color = Color3.new(0, 0.666667, 1)
		NewConnector.Anchored = true
		NewConnector.CanCollide = false
		
		NewConnector.CFrame = CFrame.new(
			Vector3.new( -- Pos
				(vec_v1.X + vec_v2.X) / 2,
				3,
				(vec_v1.Y + vec_v2.Y) / 2
			) * TILE_SIZE + GRID_ORIGIN
			,				 
			Vector3.new( -- Look At
				vec_v2.X,
				3,
				vec_v2.Y
			) * TILE_SIZE + GRID_ORIGIN
		)  

		NewConnector.Size = Vector3.new(
			TILE_SIZE / 2,
			TILE_SIZE,
			edge[3] * TILE_SIZE
		)
		
		NewConnector.Parent = workspace.VoxelFolder

	end
end



function module.buildTriangulation(triangulation)
	for _, triangle in pairs(triangulation) do
		
		local function createEdge(startPos : Vector3, endPos : Vector3)
			local edgePart = Instance.new("Part")
			edgePart.Anchored = true
			edgePart.Size = Vector3.new(.5, .5, (startPos - endPos).Magnitude) * TILE_SIZE -- Adjust thickness as needed
			edgePart.CFrame = CFrame.new(TILE_SIZE * (startPos + endPos) / 2, TILE_SIZE * endPos) + GRID_ORIGIN
			edgePart.Transparency = 0.5
			edgePart.Parent = workspace.VoxelFolder
		end
		
		local v1 = Vector3.new(triangle[1].X, 3, triangle[1].Y)
		local v2 = Vector3.new(triangle[2].X, 3, triangle[2].Y)
		local v3 = Vector3.new(triangle[3].X, 3, triangle[3].Y)

		-- Create edges for the triangle
		createEdge(v1, v2)
		createEdge(v2, v3)
		createEdge(v3, v1)
	end
end

return module
