extends RefCounted
class_name SquareMatrix

var dimension : int

var content : Array

func init(_dim : int) -> void:
	dimension = _dim
	for i in _dim:
		var row : PackedFloat32Array
		row.resize(_dim)
		row.fill(0.)
		content.append(row)

func set_ij(_i : int, _j : int, _content : float) -> void:
	content[_i][_j] = _content

func get_ij(_i : int, _j : int) -> float:
	return content[_i][_j]

## Returns submatrix obtained by removing the _ith row and the _jth column
func get_submatrix( _i : int, _j : int) -> SquareMatrix:
	var sub : SquareMatrix
	sub = SquareMatrix.new()
	sub.init(dimension-1)
	
	for i in dimension:
		if i != _i:
			for j in dimension:
				if j != _j:
					var ni = i
					var nj = j
					if i > _i: ni -= 1
					if j > _j: nj -= 1
					sub.set_ij(ni, nj, content[i][j])
	
	return sub

func get_minor(_i : int, _j : int) -> float:
	return get_submatrix(_i, _j).get_determinant()

func get_cofactor(_i : int, _j : int) -> float:
	return pow(-1, _i + _j) * get_minor(_i, _j)

func get_determinant() -> float:
	if dimension == 1: return content[0][0]
	
	if dimension == 2:
		return content[0][0]*content[1][1] - content[0][1]*content[1][0]
	
	var det : float = 0.
	
	for j in dimension:
		det += content[0][j] * get_cofactor(0, j)
	
	return det

func get_cofactor_matrix() -> SquareMatrix:
	var c : SquareMatrix
	c = SquareMatrix.new()
	c.init(dimension)
	
	for i in dimension:
		for j in dimension:
			c.set_ij(i, j, get_cofactor(i, j))
	
	return c

func get_transpose() -> SquareMatrix:
	var t : SquareMatrix
	t = SquareMatrix.new()
	t.init(dimension)
	
	for i in dimension:
		for j in dimension:
			t.set_ij(i, j, get_ij(i, j))
	
	return t

func get_adjugate() -> SquareMatrix:
	return get_cofactor_matrix().get_transpose()

func get_inverse() -> SquareMatrix:
	if dimension == 1:
		var i : SquareMatrix
		i = SquareMatrix.new()
		i.init(1)
		i.set_ij(0, 0, 1./content[0][0]) 
		return i
	
	return  get_adjugate().product_by_scalar( 1./get_determinant() )

func product_by_scalar( factor : float ) -> SquareMatrix:
	var p : SquareMatrix
	p = SquareMatrix.new()
	p.init(dimension)
	
	for i in dimension:
		for j in dimension:
			p.set_ij(i, j, factor * content[i][j])
	
	return p

func product_by_vector( vector : VectorN ) -> VectorN:
	if dimension != vector.dimension:
		push_error("Attempting to multiply a matrix and a vector of different dimensions")
		return 
	var p : VectorN
	p = VectorN.new()
	p.init(dimension)
	
	for i in dimension:
		var product : float = 0.
		for j in dimension:
			product += content[i][j] * vector.get_i(j)
		
		p.set_i(i, product)
	
	return p
