local module = {}

export type Tile = {Type: String, Tile: String}  -- Representation of one tile in the world grid
export type GridRow = {Tile}                     -- One row of tiles in the world grid
export type Grid = {GridRow}                     -- One grid of tiles
export type Coord = {x: number, z: number}       -- representation of any 2D coordinate
export type Node = {vec2: Vector2, nodelabel: number}  -- representation of a graph node, contains its label and its coordinate
export type Triangle = {a: Vector2, b: Vector2, c: Vector2}  --representation of a triangle in 2D plane
export type Triangulation = { {[number]: Triangle} }    -- a collection of triangles
export type Graph = { { [number]: Coord } }      --Adjacency List representation of a graph


return module
