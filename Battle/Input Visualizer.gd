extends Control

var StateTimer = 0
var AttackStateTimer = 0
@onready var CharRef = $"..".get_child(0)
var Joystick = Vector2(0,0)
var ChargeBackTimer
var ChargeDownTimer

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	Joystick = CharRef.JoystickInput
	StateTimer = CharRef.StateTimer
	AttackStateTimer = CharRef.AttackStateTimer
	$StateTimer.text = str(StateTimer,"\n",AttackStateTimer)
	$WhichSide.text = str(CharRef.direction())
	
	$JoystickDisplay.position.x = 52 + (Joystick.x * 13)
	$JoystickDisplay.position.y = 52 - (Joystick.y * 13)
	
	updateButton($Button_A,CharRef.ButtonAPressed)
	updateButton($Button_B,CharRef.ButtonBPressed)
	updateButton($Button_C,CharRef.ButtonCPressed)
	updateButton($Button_D,CharRef.ButtonDPressed)

func updateButton(button,input):
	var alpha = getButtonStrength(input)
	button.modulate = Color("White", alpha)
	
func getButtonStrength(input):
	if input:
		return 1
	else:
		return 0.5
