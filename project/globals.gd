extends Node

var AMBIENT_DIMENSION = 3

# 2D Transforms
var VIS_SCALE_2D = 100
var VIS_TRANSFORM_2D = Transform2D(VIS_SCALE_2D*Vector2.RIGHT,-VIS_SCALE_2D*Vector2.DOWN, Vector2.ZERO)

# Calculating time step
var CALCULATING_STEP = false
