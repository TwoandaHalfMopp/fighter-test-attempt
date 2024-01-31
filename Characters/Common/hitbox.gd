extends Area3D

@onready var parent = get_parent()

@export var width = 2.0
@export var height = 1.0
@export var depth = 1.0
@export var active = 10
@export var damage = 1
@export var hitstun = 10
@export var user_meter = 5
@export var target_meter = 2


@onready var hitbox = get_node("Hitbox Shape")
@onready var visualizer = get_node("HitboxVisualizer")
var FrameTimer = 0
var playerList = []

func set_parameters(input_width,input_height,input_depth,input_active,input_position,input_damage,input_hitstun,input_user_meter,input_target_meter):
	self.position = Vector3(0,0,0)
	playerList.append(parent)
	playerList.append(self)
	width = input_width
	height = input_height
	depth = input_depth
	active = input_active
	self.position = input_position
	damage = input_damage
	hitstun = input_hitstun
	user_meter = input_user_meter
	target_meter = input_target_meter
	update_extents()
	connect("area_entered",Callable(self,"Hitbox_Collide"))
	set_physics_process(true)
	
func Hitbox_Collide(area):
	if !(area in playerList):
		playerList.append(area)
		area.damage(damage)
		area.build_meter(target_meter)
		parent.build_meter(user_meter)
		area.hitstun = hitstun
		area.connected = true
		area.get_node("StateChart").send_event("react_hitstun")
		

func update_extents():
	hitbox.shape.extents = Vector3(width,height,depth)
	visualizer.scale = Vector3(width*2,height*2,depth*2)
	
func _ready():
	hitbox.shape = BoxShape3D.new()
	set_physics_process(false)
	pass

func _physics_process(delta):
	if FrameTimer < active:
		FrameTimer += 1
	elif FrameTimer == active:
		Engine.time_scale = 1
		queue_free()
		return
