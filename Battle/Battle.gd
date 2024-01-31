extends Node3D

@export var TestCharacter: PackedScene

@onready var p1
@onready var p2


# Called when the node enters the scene tree for the first time.
func _ready():
	var p1character = TestCharacter.instantiate()
	var p2character = TestCharacter.instantiate()
	
	$P1Character.add_child(p1character)
	$P2Character.add_child(p2character)
	p1 = $P1Character.get_child(0)
	p2 = $P2Character.get_child(0)
	
	p1.controls = load("res://player_1_controls.tres")
	p2.controls = load("res://player_2_controls.tres")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
