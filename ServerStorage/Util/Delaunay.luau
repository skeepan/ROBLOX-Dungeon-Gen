local DelaunayModule = {}

function SuperTriangle(squareDimension)
	local triangleEdgeSize = squareDimension/0.464
	local vertexL = 	Vector2.new(
		(squareDimension/2)-(triangleEdgeSize/2), 
		0
	) 
	local vertexR = Vector2.new(
		(squareDimension/2) + triangleEdgeSize/2,
		0
	)
	local vertexM = Vector2.new( 
		(squareDimension/2),
		triangleEdgeSize*math.sqrt(3)/2
		)
	return vertexL, vertexM, vertexR
end

function removeElement(tabl,index)
	table.remove(tabl,index)
	if index == #tabl+1 then return end
	if #tabl[index] < 3 then
		removeElement(tabl,index)
	end
end

function circumcenter(a,b,c)
	local ax, ay, bx, by, cx, cy = a.X, a.Y, b.X, b.Y, c.X, c.Y
	local d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
	local ux = ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay - by)) / d
	local uy = ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx - ax)) / d
	return Vector2.new(ux, uy)
end

function isPointInCircle(point,triangle)
	--print("Triangle being circumcircled = ", triangle)
	local poocenter = circumcenter(triangle[1],triangle[2],triangle[3])
	local radius = math.sqrt((poocenter.X - triangle[1].X)^2+(poocenter.Y - triangle[1].Y)^2)
	local distPC = math.sqrt((poocenter.X - point[1].X)^2+(poocenter.Y - point[1].Y)^2)
	if distPC < radius then
		return true
	else
		return false
	end
end


function DelaunayModule.BowyerWatson (pointList)
	local triangulation = {}
	local a, b, c = SuperTriangle(game.ServerStorage.Configuration.Grid.GridSize.Value)
	local SuperTriangle = {  a, b, c }
	table.insert(triangulation, SuperTriangle)

	for _, point in ipairs(pointList) do --add all the points one at a time to the triangulation
		local badTriangles = {}
		
		
		for _, triangle in ipairs(triangulation) do --first find all the triangles that are no longer valid due to the insertion
			if isPointInCircle(point, triangle) == true then
				table.insert(badTriangles, triangle)
				--print("point "..i.." is in the circumcircle of triangle "..j)
			end
		end
		
		--print("point = "..i.." badTriangles = ",badTriangles)
		local polygon = {}
		

		for _, triangle in ipairs(badTriangles) do -- find the boundary of the polygonal hole
			local edges = {
				{triangle[1], triangle[2]}, 
				{triangle[2], triangle[3]}, 
				{triangle[3], triangle[1]}
			}
			
			for _, edge in ipairs(edges) do
				local edgeShared = false

				for _, otherTriangle in ipairs(badTriangles) do -- Comparing the edge of our triangle against each other badTriangle

					if triangle ~= otherTriangle then -- Don't compare a triangle with itself (you will know because they will have the same index)
						local otherEdges = {
							{otherTriangle[1], otherTriangle[2]},
							{otherTriangle[2], otherTriangle[3]},
							{otherTriangle[3], otherTriangle[1]}
						}
						
						
						for _, otherEdge in ipairs(otherEdges) do -- Comparing against each edge in the other badTriangle (n=1,n=2,n=3)
							local shareVertex1 = false
							local shareVertex2 = false
							
							for _, otherVertex in otherEdge do -- Comparing against each vertex in the otherEdge (p=1,p=2)

								local edgeV1 = edge[1]
								local edgeV2 = edge[2]
				
								if otherVertex == edgeV1 then shareVertex1 = true end
								if otherVertex == edgeV2 then shareVertex2 = true end
							end

							if shareVertex1 == true and shareVertex2 == true then edgeShared = true end

						end
					end 


				end

				if edgeShared == false then
					table.insert(polygon, edge) --adding edge to polygon
				end

			end

		end
		--print("Polygon = ", polygon)
		for _, triangle in pairs(badTriangles) do -- remove them from the data structure
			local toBeRemoved = table.find(triangulation,triangle)
			table.remove(triangulation,toBeRemoved)
		end
		--print("new triangulation mesh = ", triangulation)

		for _, edge in pairs(polygon) do -- re-triangulate the polygonal hole
			local newTri = { point[1], edge[1], edge[2] }
			--print("newTri = ", newTri)
			table.insert(triangulation, newTri)
		end

	end	


	for _, triangle in ipairs(triangulation) do

		for _, vertex in ipairs(triangle) do
			local pointExistsInSuperTriangle = false

			for _, superV in pairs(SuperTriangle) do
				if vertex.X == superV.X and vertex.Y == superV.Y then pointExistsInSuperTriangle = true end
				if pointExistsInSuperTriangle == true then
					for x,vert in pairs(triangle) do
						local removing = table.find(triangle, vertex)
						table.remove(triangle, removing)

					end

				end		
			end


		end

	end 

	for k, triangle in pairs(triangulation) do
		if #triangle<3 then
			removeElement(triangulation, k)
		end
	end

	--print("Triangulation mesh: ",triangulation)

	return triangulation
end


return DelaunayModule


