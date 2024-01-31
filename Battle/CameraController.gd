extends Node3D

@onready var p1 = $"../../P1Character".get_child(0)
@onready var p2 = $"../../P2Character".get_child(0)
@onready var midpoint
@onready var maincam = $BGCamera/SubViewportContainer/SubViewport/MainCamera
@onready var bgcam = $BGCamera
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	midpoint = (p1.global_position.x + p2.global_position.x) * 0.5
	$MidpointVisualizer.global_position.x = midpoint
	bgcam.global_position.x = midpoint
	maincam.global_position.x = midpoint
	#$Label.text = str("P1: ",p1.global_position.x,"\nP2: ",p2.global_position.x,"\nCamera: ",self.global_position.x)
	
