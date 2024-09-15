local GraphModule = {}

local function UnHashGraph(adjlist, CoordHash)
	local graph = {}
	for vtx_v2, adjacentlist in pairs(adjlist) do
		local i_vtx = CoordHash[vtx_v2]
		graph[i_vtx] = {}
		for edge, _ in pairs(adjlist[vtx_v2]) do
			local i_adjvtx = CoordHash[edge]
			table.insert(graph[i_vtx], i_adjvtx)
		end
	end
	return graph	
end

function GraphModule.makeGraph(triangulation, pointList)
	local graph = {}
	local CoordHash = {}
	local IndexToPoint = {}

	-- Hash the coordinates with point index
	for i, vrtx in ipairs(pointList) do
		CoordHash[vrtx[1]] = i
		IndexToPoint[i] = vrtx[1]
	end

	-- Initialize the graph with empty adjacency lists
	for _, point in ipairs(pointList) do
		graph[point[1]] = {}
	end

	-- Populate the adjacency lists
	for _, triangle in ipairs(triangulation) do
		for i = 1, 3 do
			local point = triangle[i]
			local neighbor1 = triangle[(i % 3) + 1]
			local neighbor2 = triangle[((i + 1) % 3) + 1]

			-- Ensure the point exists in the graph
			if not graph[point] then
				graph[point] = {}
			end

			-- Add neighbors to the adjacency list if they are not already present
			graph[point][neighbor1] = true
			graph[point][neighbor2] = true
		end
	end

	return UnHashGraph(graph, CoordHash), CoordHash
end

function GraphModule.Prims(graph, pointList)
	local visited = table.create(#graph, nil)
	local mst = table.create(#graph - 1)
	local start : number = 1 -- Get the starting vertex in the graph
	-- Priority queue to store the edges
	local pq = {}

	-- Helper function to add edges to the priority queue
	local function addEdges(point)
		for n, neighbor in ipairs(graph[point]) do 
				table.insert(pq, 
					{	point,
						neighbor,
						(pointList[point][1] - pointList[neighbor][1]).Magnitude
					}
				)
		end
	end

	-- Initialize with the start point
	visited[start] = true
	addEdges(start)
	
	while #pq > 0 do
		-- Sort the priority queue based on edge weights
		table.sort(pq, function(a, b) return a[3] < b[3] end)
		
		-- Get the edge with the least weight
		local edge = table.remove(pq, 1)
		local u, v, weight = edge[1], edge[2], edge[3]

		if not visited[v] then
			visited[v] = true
			table.insert(mst, edge)
			addEdges(v)
			
		end
	end

	return mst
end


return GraphModule
