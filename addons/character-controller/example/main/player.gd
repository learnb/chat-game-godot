extends FPSController3D
class_name Player

## Example script that extends [CharacterController3D] through 
## [FPSController3D].
## 
## This is just an example, and should be used as a basis for creating your 
## own version using the controller's [b]move()[/b] function.
## 
## This player contains the inputs that will be used in the function 
## [b]move()[/b] in [b]_physics_process()[/b].
## The input process only happens when mouse is in capture mode.
## This script also adds submerged and emerged signals to change the 
## [Environment] when we are in the water.

@export var input_back_action_name := "move_backward"
@export var input_forward_action_name := "move_forward"
@export var input_left_action_name := "move_left"
@export var input_right_action_name := "move_right"
@export var input_sprint_action_name := "move_sprint"
@export var input_jump_action_name := "move_jump"
@export var input_crouch_action_name := "move_crouch"
@export var input_fly_mode_action_name := "move_fly_mode"

@export var underwater_env: Environment
@onready var voxelTerrain: VoxelLodTerrain = $"../VoxelLodTerrain"
@onready var voxel_tool_target: Marker3D = $VoxelToolTarget
@onready var voxel_tool_ray_cast: RayCast3D = $VoxelToolRayCast
#@onready var voxel_tool_ray_cast: RayCast3D = $Head/FirstPersonCameraReference/Camera3D/VoxelToolRayCast
@onready var camera_3d: Camera3D = $Head/FirstPersonCameraReference/Camera3D
var dig_size: float

var voxelTool: VoxelTool
var debugLineMesh: ImmediateMesh
#var debug_material : ORMMaterial3D
var debug_material : StandardMaterial3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup()
	#emerged.connect(_on_controller_emerged.bind())
	#submerged.connect(_on_controller_subemerged.bind())

	voxelTool = voxelTerrain.get_voxel_tool()
	voxelTool.mode = VoxelTool.MODE_ADD
	dig_size = 0.5

	voxel_tool_ray_cast.debug_shape_custom_color = Color.GREEN
	voxel_tool_ray_cast.debug_shape_thickness = 3.0
	
	debugLineMesh = ImmediateMesh.new()
	#debug_material = ORMMaterial3D.new()
	debug_material = StandardMaterial3D.new()
	#debug_material = preload("res://debug_material.tres")
	#debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	#debug_material.albedo_color = Color.GREEN

func _process(_delta: float) -> void:
	pass
	draw_debug_line()

func draw_debug_line() -> void:
	#var startPoint = self.global_position
	#var endPoint = voxel_tool_target.global_position
	#print("[debug draw] line(%s, %s)" % [startPoint, endPoint])

	##DebugDraw3D.draw_line(startPoint, endPoint, Color.GREEN)
	#debugLineMesh.clear_surfaces()
	#debugLineMesh.surface_begin(Mesh.PRIMITIVE_LINES, debug_material)
	##debugLineMesh.surface_set_color(debug_material.albedo_color)
	#debugLineMesh.surface_add_vertex(startPoint)
	##debugLineMesh.surface_set_color(debug_material.albedo_color)
	#debugLineMesh.surface_add_vertex(endPoint)
	#debugLineMesh.surface_end()

	pass


func _physics_process(delta):
	var is_valid_input := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	
	if is_valid_input:
		if Input.is_action_just_pressed(input_fly_mode_action_name):
			fly_ability.set_active(not fly_ability.is_actived())
		var input_axis = Input.get_vector(input_left_action_name, input_right_action_name, input_back_action_name, input_forward_action_name)
		var input_jump = Input.is_action_just_pressed(input_jump_action_name)
		var input_crouch = Input.is_action_pressed(input_crouch_action_name)
		var input_sprint = Input.is_action_pressed(input_sprint_action_name)
		var input_swim_down = Input.is_action_pressed(input_crouch_action_name)
		var input_swim_up = Input.is_action_pressed(input_jump_action_name)
		move(delta, input_axis, input_jump, input_crouch, input_sprint, input_swim_down, input_swim_up)
		var input_dig = Input.is_action_pressed("action_dig")
		var switch_dig_mode = Input.is_action_just_pressed("action_switch")
		if switch_dig_mode:
			switch_dig_mode()
		if input_dig:
			dig()
	else:
		# NOTE: It is important to always call move() even if we have no inputs 
		## to process, as we still need to calculate gravity and collisions.
		move(delta)


func _input(event: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_head(event.screen_relative)
		update_tool_target()


	# Get mouse position from screen space to global space (projection)

	#if event is InputEventMouseMotion:
		## Adjust voxel tool target position
		#voxel_tool_target.global_position = get_mouse_position_in_global_space()
		#voxel_tool_ray_cast.target_position = get_mouse_position_in_global_space(event)
		#voxel_tool_ray_cast.force_raycast_update()
		#voxel_tool_target.global_position = voxel_tool_ray_cast.get_collision_point()

func update_tool_target():
	var mouse_pos = get_mouse_position_in_global_space()
	get_mouse_position_in_global_space_collision()
	#var mouse_pos_collide = get_mouse_position_in_global_space_collision()
	#print("mouse pos [g]: %s" % [mouse_pos])
	#print("mouse pos [c]: %s" % [mouse_pos_collide])
	#voxel_tool_target.global_position = mouse_pos_collide
	
	voxel_tool_target.global_position = mouse_pos


func dig():
	print("[dig] at %s" % [voxel_tool_target.global_position])
	voxelTool.do_sphere(voxel_tool_target.global_position, dig_size)
	
	#print("[dig] at (%s), (%s)" % [self.global_position, voxel_tool_target.global_position])
	#voxelTool.do_path([self.global_position, voxel_tool_target.global_position], [dig_size, dig_size])

func switch_dig_mode():
	if switch_dig_mode:
		if voxelTool.mode == voxelTool.MODE_ADD:
			voxelTool.mode = VoxelTool.MODE_REMOVE
			dig_size = 3.0
		elif voxelTool.mode == voxelTool.MODE_REMOVE:
			voxelTool.mode = VoxelTool.MODE_ADD
			dig_size = 5.0

func get_mouse_position_in_global_space():
	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin = camera_3d.project_ray_origin(mouse_position)
	var ray_normal = camera_3d.project_ray_normal(mouse_position)
	return ray_origin + ray_normal * 10.0

func get_mouse_position_in_global_space_collision():
	var mouse_position = get_viewport().get_mouse_position()
	voxel_tool_ray_cast.target_position = get_mouse_position_in_global_space()
	voxel_tool_ray_cast.force_raycast_update()
	if voxel_tool_ray_cast.is_colliding():
		return voxel_tool_ray_cast.get_collision_point()
	return voxel_tool_ray_cast.target_position

#func _on_controller_emerged():
	#camera.environment = null
#
#
#func _on_controller_subemerged():
	#camera.environment = underwater_env
