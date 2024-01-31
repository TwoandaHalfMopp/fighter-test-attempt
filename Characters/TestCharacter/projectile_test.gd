extends Area3D

@export var projectile_speed = 0.25
@onready var parent = get_parent()
@export var duration = 120
@export var damage = 10
@export var hitstun = 30
@export var target_meter = 2
@export var user_meter = 5
@export var trueParent = 0

var LifeTimer = 0
var dirX = 1
var dirY = 0
var playerList = []

const angleConversion = PI/180

# Called when the node enters the scene tree for the first time.
func _ready():
	playerList.append(parent)
	set_physics_process(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	LifeTimer += floor(delta * 60)
	if LifeTimer == duration:
		queue_free()
	var motion = Vector3(dirX,dirY,0).normalized() * projectile_speed
	set_global_position(get_global_position() + motion)
	global_position.direction_to(motion)
	
	#set_rotation_degrees(rad_to_deg(Vector2(dirX,dirY).angle()))
	
func dir(directionX,directionY):
	dirX = directionX
	dirY = directionY



func _on_body_entered(body):
	if !(body in playerList) && !body is StaticBody3D:
		playerList.append(body)
		body.hitstun = hitstun
		body.damage(damage)
		body.build_meter(target_meter)
		trueParent.build_meter(user_meter)
		body.connected = true
		body.get_node("StateChart").send_event("react_hitstun")
		queue_free()
	elif body is StaticBody3D:
		queue_free()
