extends RigidBody3D

var entity_id: int:
	get:
		return entity_id
	set(value):
		entity_id = value

var entity: StdbEntity:
	get:
		return entity 
	set(value):
		entity = value
		entity_id = entity.entity_id

var stdbClient:
	get:
		return stdbClient
	set(value):
		stdbClient = value

var prevPosition: Vector3
var prevRotation: Vector3

func _ready() -> void:
	pass
	self.position = self.entity.position
	self.rotation = self.entity.rotation	
	
	# randomize initial position
	#self.position = Vector3(randf_range(-100, 100), randf_range(-100, 100), randf_range(-100, 100))
	#self.position = Vector3(
	#	randf_range(-15, 15), 
	#	randf_range(-15, 15), 
	#	randf_range(-15, 15)
	#)
	#sync_entity(true)

func _process(_delta: float) -> void:
	sync_entity()
	pass

func despawn() -> void:
	set_process(false)
	queue_free()

func sync_entity(first_time: bool=false) -> void:
	if !stdbClient.isSocketOpen:
		return

	if (self.position == prevPosition)	and (self.rotation == prevRotation):
		return
	
	prevPosition = self.position
	prevRotation = self.rotation

	if first_time:
		var argData = JSON.stringify([
			"ball",
			{
				"X": self.position.x,
				"Y": self.position.y,
				"Z": self.position.z
			},
			{
				"X": self.rotation.x,
				"Y": self.rotation.y,
				"Z": self.rotation.z
			}
		])
	
		stdbClient.callReducer("InsertEntity", argData)
	else:
		var argData = JSON.stringify([
			entity_id,
			{
				"X": self.position.x,
				"Y": self.position.y,
				"Z": self.position.z
			},
			{
				"X": self.rotation.x,
				"Y": self.rotation.y,
				"Z": self.rotation.z
			}
		])
	
		stdbClient.callReducer("UpdateEntity", argData)
