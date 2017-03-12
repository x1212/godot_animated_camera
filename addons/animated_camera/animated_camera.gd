extends Spatial

export(NodePath) var to_pos_node
export(bool) var use_pos_node = false
export(Vector3) var to_pos = Vector3(0.0,0.0,0.0)
export(float) var to_distance = 2.0
export(float) var to_angle = 45.0
export(float) var to_circle_angle = 0.0
export(bool) var circling_enabled = true
export(float) var circling_seconds = 4.0
export(float) var to_fovy = 60.0
export(float) var in_seconds = 1.0
export(float) var transition_progress = 1.0 # export, so it can be animated for non linear transitions (might be buggy)
export(bool) var transition_trigger = false # toggle to true to start transition


var from_pos = Vector3(0.0,0.0,0.0)
var from_distance = 2.0
var from_angle = 45.0
var from_circle_angle = 0.0
var from_fovy = 60.0

var circle_node
var angle_node
var distance_node
var camera_node

func _ready():
	circle_node = get_node("circling")
	angle_node = get_node("circling/angle")
	distance_node = get_node("circling/angle/distance")
	camera_node = get_node("circling/angle/distance/Camera")
	if ( circle_node == null ):
		circle_node = Spatial.new()
		add_child(circle_node)
		angle_node = Spatial.new()
		angle_node.set_rotation_deg(Vector3(-from_angle,0.0,0.0))
		circle_node.add_child(angle_node)
		distance_node = Spatial.new()
		angle_node.add_child(distance_node)
		distance_node.set_translation(Vector3(0.0,0.0,from_distance))
		camera_node = Camera.new()
		distance_node.add_child(camera_node)
	set_process( true )

var to_reached = false
func start_transition():
	transition_progress = 0.0
	to_reached = false
	from_pos = get_translation()
	from_angle = -angle_node.get_rotation_deg().x
	from_circle_angle = circle_node.get_rotation_deg().y
	from_distance = distance_node.get_translation().z
	from_fovy = camera_node.get_fov()

var circling_angle = 0.0
var circle_time_left = 0.0
var old_transition_trigger = false
func _process(delta):
	
	if ( (transition_trigger != old_transition_trigger) and (transition_trigger == true) ):
		start_transition()
	
	if ( circling_enabled == true ): # circling loop
		if ( circle_time_left > 0.0 ):
			circle_time_left -= delta
		else:
			circle_time_left = circling_seconds
		circling_angle = (circle_time_left/circling_seconds)*(2.0*PI)
	elif (transition_progress < 1.0) : # circle_angle filter
		var circling_angle_diff = to_circle_angle/360.0*2.0*PI - circling_angle
		circling_angle += 4*(circling_angle_diff)*delta/in_seconds # todo: check if there is a better way that will finish the transition within the given time (in_seconds)
	# apply circling
	circle_node.set_rotation(Vector3(0.0,circling_angle,0.0))
	
	
	if ( transition_progress < 1.0 ):
		transition_progress += delta/in_seconds
		
		if ( use_pos_node == true ): # update to_pos
			var to_pos_node_tmp = get_node(to_pos_node)
			if ( to_pos_node_tmp extends Spatial ):
				to_pos = to_pos_node_tmp.get_translation()
		
		set_translation( from_pos.linear_interpolate(to_pos,transition_progress) )
		angle_node.set_rotation( Vector3(-from_angle/360.0*2.0*PI,0.0,0.0).linear_interpolate(Vector3(-to_angle/360.0*2.0*PI,0.0,0.0),transition_progress) )
		distance_node.set_translation( Vector3(0.0,0.0,from_distance).linear_interpolate(Vector3(0.0,0.0,to_distance),transition_progress) )
		
	elif ( (use_pos_node == true) and (to_reached == true) ) : # update translation with to_pos_node in case the to_pos_node is moving
		var to_pos_node_tmp = get_node(to_pos_node)
		if ( to_pos_node_tmp extends Spatial ):
			to_pos = to_pos_node_tmp.get_translation()
		set_translation( to_pos )