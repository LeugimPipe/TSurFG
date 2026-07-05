extends QuantityInterface
class_name VolumeBody

## Volume computation strategy class.

func set_id(_id) -> void:
	super(_id)
	GRAD_KEY = "grad_volume_body_" + str(id) + "_key"

var oid : int = -1

func _init(_geom : Geometry, _oid : int = -1) -> void:
	super(_geom)
	if _oid != -1: oid = _oid
	GRAD_KEY = "grad_volume_body_" + str(id) + "_key"
	description = "Body volume"

func calc_grad_vertex(_v : Vertex, _neg : bool = false) -> void:
	super(_v)
	for fid in _v.con_facets:
		var f = geom.facets[fid]
		if f.is_quantity_connected(self):
			var q = f.get_next_vertex(_v).get_as_vector()
			var r = f.get_prev_vertex(_v).get_as_vector()
			var prod = q.cross(r)
			
			# If the id is negative the volume contribution should be the opposite
			# as the actual volume contribution is the one that would result from a
			# facet with the opposite orientation.
			if f.is_quantity_inverse(self): prod = -prod
			
			if _neg: prod = -prod
			
			_v.add_force( GRAD_KEY, [ 1/6. * prod.x, 1/6. * prod.y, 1/6. * prod.z] )

func calc_energy() -> float:
	var vol = 0.
	
	for i in facets.size():
		var f = facets[i]
		var vol_contr : float = f.volume_contribution()
		# If the id is negative the volume contribution should be the opposite
		# as the actual volume contribution is the one that would result from a
		# facet with the opposite orientation.
		if facet_ids[i] < 0 : vol_contr = -vol_contr
		vol += vol_contr
	
	return vol
