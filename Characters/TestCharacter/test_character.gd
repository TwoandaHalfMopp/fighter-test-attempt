extends CharacterBody3D

const MaxHealth = 100
const MaxSuper = 300
var CurrentHealth = 100
var CurrentSuper = 0

const MaxAirSpecials = 1
var CurrentAirSpecials = 1
var AirButtonStorage

@export var controls: Resource = null
@onready var ProjectileSpawner = get_node("ProjectileSpawner")
@onready var PlayerIndex = controls.player_index

@onready var root = $"../.."
@onready var P1Identifier = root.get_node("P1Character").get_child(0)
@onready var P2Identifier = root.get_node("P2Character").get_child(0)

const SPEED = 5.0
const ACCEL = 4.0
const JUMP_VELOCITY = 12
const JUMPSQUAT = 4
const GRAVITY = 0.5
const AIRCONTROL = 1
const maxDistance = 5.45

var hitstun:int
var connected:bool

@export var hitbox: PackedScene
@export var projectile: PackedScene

var InputBuffer = []
const BufferSizeLimit = 35
var CurrentInput = Vector3(2,2,0)
var PrevInput = Vector3(2,2,0)
var InputByte
var InputBufferTimer = 0
const InputBufferLimit = 5
const ChargeTimerLimit = 30
enum InputBitFlag {Left = 1, Right = 2, Up = 4, Down = 8, ButtonA = 16, ButtonB = 32, ButtonC = 64, ButtonD = 128}

var InputLeftPressed
var InputRightPressed
var InputUpPressed
var InputDownPressed
var JoystickInput = Vector2(0,0)
var ButtonAPressed
var ButtonBPressed
var ButtonCPressed
var ButtonDPressed

var BackChargeTimer = 0
var DownChargeTimer = 0
var BackChargeCoyote = 60
var DownChargeCoyote = 60

var StateTimer
var AttackStateTimer
var AllowMovementInput = true
var FacingDir = -1

func _ready():
	CurrentHealth = MaxHealth
	CurrentSuper = 0
	InitializeInputBuffer()
	$Control/StateChartDebugger.position.x += controls.player_index * 700
	set_collision_layer_value(controls.player_index+2,true)

func InitializeInputBuffer():
	for i in BufferSizeLimit-1:
		InputBuffer.append(Vector3(0,0,0))

func resetStateTimer():
	StateTimer = 0

func updateStateTimer():
	if StateTimer < 1000:
		StateTimer += 1

func updateInputVariables():
	InputLeftPressed = Input.is_action_pressed(controls.Input_Left)
	InputRightPressed = Input.is_action_pressed(controls.Input_Right)
	InputUpPressed = Input_Ups()
	InputDownPressed = Input.is_action_pressed(controls.Input_Down)
	
	if InputLeftPressed && InputRightPressed:
		InputLeftPressed = 0
		InputRightPressed = 0
	
	if InputDownPressed && InputUpPressed:
		InputDownPressed = 0
	
	JoystickInput.x = int(InputRightPressed) - int(InputLeftPressed)
	JoystickInput.y = int(InputUpPressed) - int(InputDownPressed)
	
	ButtonAPressed = Input.is_action_pressed(controls.Input_Button_A)
	ButtonBPressed = Input.is_action_pressed(controls.Input_Button_B)
	ButtonCPressed = Input.is_action_pressed(controls.Input_Button_C)
	ButtonDPressed = Input.is_action_pressed(controls.Input_Button_D)

func Input_Ups():
	if Input.is_action_pressed(controls.Input_Up) || Input.is_action_pressed(controls.Input_Up_Alt):
		return true
	else:
		return false

func direction():
	if self.global_position.x > $"../../Stage/CameraController".midpoint:
		FacingDir = -1
		return true
	else:
		FacingDir = 1
		return false
	
func create_hitbox(width,height,depth,active,inputPosition,inputDamage,inputHitstun,inputUserMeter,inputTargetMeter):
	var hitbox_instance = hitbox.instantiate()
	var shrink = 10
	self.add_child(hitbox_instance)
	
	if !direction():
		hitbox_instance.set_parameters(float(width)/shrink,float(height)/shrink,float(depth),active,inputPosition,inputDamage,inputHitstun,inputUserMeter,inputTargetMeter)
		
	else:
		var flip_x_positions = Vector3(-inputPosition.x,inputPosition.y,inputPosition.z)
		hitbox_instance.set_parameters(float(width)/shrink,float(height)/shrink,float(depth),active,flip_x_positions,inputDamage,inputHitstun,inputUserMeter,inputTargetMeter)
	return hitbox_instance
	
func create_projectile(dir_x,dir_y,point):
	var projectile_instance = projectile.instantiate()
	projectile_instance.playerList.append(self)
	projectile_instance.trueParent = self
	get_parent().get_parent().add_child(projectile_instance)
	
	ProjectileSpawner.set_position(point)
	
	if !direction():
		projectile_instance.dir(dir_x,dir_y)
		projectile_instance.set_global_position(ProjectileSpawner.get_global_position())
	else:
		ProjectileSpawner.position.x *= -1
		projectile_instance.dir(-dir_x,dir_y)
		projectile_instance.set_global_position(ProjectileSpawner.get_global_position())
	return projectile_instance

func GetInputReturn():
	var _ret = 0
	_ret = _ret | int(InputLeftPressed) * InputBitFlag.Left
	_ret = _ret | int(InputRightPressed) * InputBitFlag.Right
	_ret = _ret | int(InputUpPressed) * InputBitFlag.Up
	_ret = _ret | int(InputDownPressed) * InputBitFlag.Down
	
	_ret = _ret | int(ButtonAPressed) * InputBitFlag.ButtonA
	_ret = _ret | int(ButtonBPressed) * InputBitFlag.ButtonB
	_ret = _ret | int(ButtonCPressed) * InputBitFlag.ButtonC
	_ret = _ret | int(ButtonDPressed) * InputBitFlag.ButtonD
	return _ret
func updateInputBuffer():
	if JoystickInput == Vector2(PrevInput.x,PrevInput.y):
		if InputBuffer[0].z < 1000:
			InputBuffer[0].z += 1
	else:
		PrevInput = Vector3(JoystickInput.x,JoystickInput.y,1)
		InputBuffer.push_front(Vector3(JoystickInput.x,JoystickInput.y,1))
		if InputBuffer.size() > 35:
			InputBuffer.pop_back()
	$Control/InputBufferChecker.text = str(InputBuffer)
	
func any_back(index):
	if FacingDir * index.x == -1:
		return true
	else:
		return false
func any_forward(index):
	if FacingDir * index.x == 1:
		return true
	else:
		return false
func any_up(index):
	if index.y == 1:
		return true
	else:
		return false
func any_down(index):
	if index.y == -1:
		return true
	else:
		return false

func up_back(index):
	if FacingDir * index.x == -1 && index.y == 1:
		return true
	else:
		return false
func up(index):
	if FacingDir * index.x == 0 && index.y == 1:
		return true
	else:
		return false
func up_forward(index):
	if FacingDir * index.x == 1 && index.y == 1:
		return true
	else:
		return false
func back(index):
	if FacingDir * index.x == -1 && index.y == 0:
		return true
	else:
		return false
func neutral(index):
	if index.x == 0 && index.y == 0:
		return true
	else:
		return false
func forward(index):
	if FacingDir * index.x == 1 && index.y == 0:
		return true
	else:
		return false
func down_back(index):
	if FacingDir * index.x == -1 && index.y == -1:
		return true
	else:
		return false
func down(index):
	if FacingDir * index.x == 0 && index.y == -1:
		return true
	else:
		return false
func down_forward(index):
	if FacingDir * index.x == 1 && index.y == -1:
		return true
	else:
		return false

func CheckMotion(motion):
	var index = 0
	var num = 0
	if Vector2(InputBuffer[0].x,InputBuffer[0].y) == Vector2(0,0) && InputBuffer[0].z <= InputBufferLimit:
		num = 1
	match motion:
		"236236":
			var anyindex = 0
			var TempBuffer = InputBuffer
			var expectedSize = 6
			if forward(TempBuffer[num]) && TempBuffer[num].z <= InputBufferLimit:
				index += 1
			for i in 1:
				if any_down(InputBuffer[num+i+1]) && InputBuffer[num+i+1].z <= InputBufferLimit:
					anyindex+= 1
			if anyindex > 0:
					index += 1
			if anyindex < 2:
				expectedSize -= 1
			for i in range(2,10):
				if Vector2(TempBuffer[num+i].x,TempBuffer[num+i].y) == Vector2(0,0) && TempBuffer[num+i].z <= InputBufferLimit:
					TempBuffer.remove_at(num+i)
					TempBuffer.append(Vector3(0,0,0))
					break
			for i in 1:
				if any_forward(TempBuffer[num+i+2]) && TempBuffer[num+i+2].z <= InputBufferLimit:
					anyindex+= 1
			if anyindex > 0:
					index += 1
			if anyindex < 2:
				expectedSize -= 1
			if down(TempBuffer[num+expectedSize+1]):
				index += 1
			if index == 4:
				return true
			else:
				return false
			
		"214214":
			var anyindex = 0
			var TempBuffer = InputBuffer
			var expectedSize = 6
			if back(TempBuffer[num]) && TempBuffer[num].z <= InputBufferLimit:
				index += 1
			for i in 1:
				if any_down(InputBuffer[num+i+1]) && InputBuffer[num+i+1].z <= InputBufferLimit:
					anyindex+= 1
			if anyindex > 0:
					index += 1
			if anyindex < 2:
				expectedSize -= 1
			for i in range(2,10):
				if Vector2(TempBuffer[num+i].x,TempBuffer[num+i].y) == Vector2(0,0) && TempBuffer[num+i].z <= InputBufferLimit:
					TempBuffer.remove_at(num+i)
					TempBuffer.append(Vector3(0,0,0))
					break
			for i in 1:
				if any_back(TempBuffer[num+i+2]) && TempBuffer[num+i+2].z <= InputBufferLimit:
					anyindex+= 1
			if anyindex > 0:
					index += 1
			if anyindex < 2:
				expectedSize -= 1
			if down(TempBuffer[num+expectedSize+1]):
				index += 1
			if index == 4:
				return true
			else:
				return false
				
		"4x646":
			var TempBuffer = InputBuffer
			var RemovedFrames = 0
			if BackChargeTimer < ChargeTimerLimit || 60 - BackChargeCoyote > InputBufferLimit * 3:
				return false
			for i in 3:
				if Vector2(TempBuffer[num+1+i].x,TempBuffer[num+1+i].y) == Vector2(0,0) && TempBuffer[num+1+i].z <= InputBufferLimit:
					RemovedFrames = TempBuffer[num+1].z
					TempBuffer.remove_at(num+1+i)
					TempBuffer.append(Vector3(0,0,0))
			if Vector2(TempBuffer[num+3].x,TempBuffer[num+3].y) == Vector2(0,-1) && TempBuffer[num+3].z + RemovedFrames <= InputBufferLimit:
				TempBuffer.remove_at(num+3)
				TempBuffer.append(Vector3(0,0,0))
			if forward(TempBuffer[num]):
				index += 1
			if back(TempBuffer[num+1]):
				index += 1
			if forward(TempBuffer[num+2]):
				index += 1
			if any_back(TempBuffer[num+3]):
				index += 1
			if index == 4:
				return true
			else:
				return false
			
		
		"63214":
			var anyindex = 0
			for i in range(3,0,-1):
				if any_down(InputBuffer[num+i]) && InputBuffer[num+i].z <= InputBufferLimit:
					anyindex += 1
			if anyindex > 0:
				index += 1
			if any_forward(InputBuffer[num+anyindex+1]):
				index += 1
			if back(InputBuffer[num]) && InputBuffer[num].z <= InputBufferLimit:
				index += 1

			if index == 3:
				return true
			else:
				return false
		"41236":
			var anyindex = 0
			for i in range(3,0,-1):
				if any_down(InputBuffer[num+i]) && InputBuffer[num+i].z <= InputBufferLimit:
					anyindex += 1
			if anyindex > 0:
				index += 1
			if any_back(InputBuffer[num+anyindex+1]):
				index += 1
			if forward(InputBuffer[num]) && InputBuffer[num].z <= InputBufferLimit:
				index += 1

			if index == 3:
				return true
			else:
				return false
		"623":
			if any_forward(InputBuffer[num]):
				index += 1
			if any_down(InputBuffer[num+1]) && InputBuffer[num+1].z <= InputBufferLimit:
				index+= 1
			if any_forward(InputBuffer[num+2]) && InputBuffer[num+1].z <= InputBufferLimit:
				index += 1
			if index == 3:
				return true
			else:
				return false
		"236":
			if down(InputBuffer[num+2]):
				index += 1
			if down_forward(InputBuffer[num+1]) && InputBuffer[num+1].z <= InputBufferLimit:
				index += 1
			if forward(InputBuffer[num]) && InputBuffer[num].z <= InputBufferLimit:
				index += 1
			if index == 3:
				return true
			else:
				return false
		"214":
			if down(InputBuffer[num+2]):
				index += 1
			if down_back(InputBuffer[num+1]) && InputBuffer[num+1].z <= InputBufferLimit:
				index += 1
			if back(InputBuffer[num]) && InputBuffer[num].z <= InputBufferLimit:
				index += 1
			if index == 3:
				return true
			else:
				return false
		"4x6":
			var TempBuffer = InputBuffer
			var RemovedFrames = 0
			if BackChargeTimer < ChargeTimerLimit || 60 - BackChargeCoyote > InputBufferLimit:
				return false
			if Vector2(TempBuffer[num+1].x,TempBuffer[num+1].y) == Vector2(0,0) && TempBuffer[num+1].z <= InputBufferLimit:
				RemovedFrames = TempBuffer[num+1].z
				TempBuffer.remove_at(num+1)
				TempBuffer.append(Vector3(0,0,0))
			for i in 1:
				if Vector2(TempBuffer[num+i+1].x,TempBuffer[num+i+1].y) == Vector2(0,-1) && TempBuffer[num+i+1].z + RemovedFrames <= InputBufferLimit:
					TempBuffer.remove_at(num+i+1)
					TempBuffer.append(Vector3(0,0,0))
			if forward(TempBuffer[num]):
				return true
			else:
				return false
		"2x8":
			var TempBuffer = InputBuffer
			var RemovedFrames = 0
			if DownChargeTimer < ChargeTimerLimit || 60 - DownChargeCoyote > InputBufferLimit:
				return false
			if Vector2(TempBuffer[num+1].x,TempBuffer[num+1].y) == Vector2(0,0) && TempBuffer[num+1].z <= InputBufferLimit:
				RemovedFrames = TempBuffer[num+1].z
				TempBuffer.remove_at(num+1)
				TempBuffer.append(Vector3(0,0,0))
			for j in 1:
				for i in range(-1,2,2):
					if Vector2(TempBuffer[num+j+1].x,TempBuffer[num+j+1].y) == Vector2(i,0) && TempBuffer[num+j+1].z + RemovedFrames <= InputBufferLimit:
						TempBuffer.remove_at(num+j+1)
						TempBuffer.append(Vector3(0,0,0))
			if any_up(TempBuffer[num]):
				return true
			else:
				return false
		"22":
			if down(InputBuffer[num]):
				index += 1
			if neutral(InputBuffer[num+1]) && InputBuffer[num+1].z <= InputBufferLimit:
				index += 1
			if down(InputBuffer[num+2]) && InputBuffer[num+2].z <= InputBufferLimit:
				index += 1
			if index == 3:
				return true
			else:
				return false
		_:
			return false

func CheckForSpecials(els):
	var c = ""
	match els:
		"a":
			if !is_on_floor():
				c = "j"
			if is_on_floor() && forward(JoystickInput):
				c = "6"
			if CheckMotion("236"):
				if is_on_floor():
					c = "236"
				elif CurrentAirSpecials > 0:
					c = "j236"
			if is_on_floor() && CheckMotion("214"):
					c = "214"
				
			if CurrentSuper >= 100:
				if is_on_floor() && CheckMotion("236236"):
					c = "236236"
				if CheckMotion("214214"):
					c = "214214"
		"b":
			if !is_on_floor() && any_down(JoystickInput):
				c = "j2"
			if CheckMotion("4x6"):
				c = "4x6"
			if CheckMotion("2x8"):
				c = "2x8"
			if CheckMotion("63214"):
				c = "63214"
			
			if CurrentSuper >= 100:
				if CheckMotion("4x646"):
					c = "4x646"

		"c":
			if CheckMotion("623"):
				c = "623"
			if CheckMotion("41236"):
				c = "41236"
		"d":
			if CheckMotion("22"):
				c = "22"
	return str("input_",c,els)
	
func updateChargeTimers():
	if any_back(JoystickInput):
		if BackChargeTimer < ChargeTimerLimit:
			BackChargeTimer += 1
		if BackChargeCoyote < 60:
			BackChargeCoyote = 60
	else:
		if BackChargeCoyote > 0:
			BackChargeCoyote -= 1
		else:
			BackChargeTimer = 0
	if any_down(JoystickInput):
		if DownChargeTimer < ChargeTimerLimit:
			DownChargeTimer += 1
		if DownChargeCoyote < 60:
			DownChargeCoyote = 60
	else:
		if DownChargeCoyote > 0:
			DownChargeCoyote -= 1
		else:
			DownChargeTimer = 0
	$Control/InputVarDebug.text = str(BackChargeTimer," ",BackChargeCoyote,"\n",DownChargeTimer," ",DownChargeCoyote)
	
func CheckButtons():
	match [ButtonAPressed,ButtonBPressed,ButtonCPressed,ButtonDPressed]:
		[true,false,false,false]:
			$StateChart.send_event(CheckForSpecials("a"))
		[false,true,false,false]:
			$StateChart.send_event(CheckForSpecials("b"))
		[false,false,true,false]:
			$StateChart.send_event(CheckForSpecials("c"))
		[false,false,false,true]:
			$StateChart.send_event(CheckForSpecials("d"))
		_:
			pass
	
func _physics_process(delta):
	
	updateInputVariables()
	updateInputBuffer()
	updateChargeTimers()
	position.z = 0
	
			
	match int(JoystickInput.y):
		-1:
			$StateChart.send_event("input_crouch")
		0:
			$StateChart.send_event("input_idle")
		1:
			$StateChart.send_event("input_jump")
		var MatchValue:
			print(MatchValue)
		
	position.x += velocity.x * delta

func damage(input):
	if CurrentHealth > 0:
		if CurrentHealth - input > 0:
			CurrentHealth -= input
		else:
			CurrentHealth = 0
func build_meter(input):
	if CurrentSuper < MaxSuper:
		if CurrentSuper + input < MaxSuper:
			CurrentSuper += input
		else:
			CurrentSuper = MaxSuper
func spend_meter(input):
	CurrentSuper -= input

func _on_idle_state_entered():
	resetStateTimer()
	$MeshInstance3D.scale.y = 1
	$MeshInstance3D.position.y = 1


func _on_crouch_state_entered():
	resetStateTimer()
	$MeshInstance3D.scale.y = 0.5
	$MeshInstance3D.position.y = 0.5


func _on_jump_squat_state_entered():
	resetStateTimer()
	$MeshInstance3D.scale.y = 0.75
	$MeshInstance3D.position.y = 0.75

func _on_jump_squat_state_exited():
	velocity.y = JUMP_VELOCITY
	velocity.x = JoystickInput.x * SPEED
	AirButtonStorage = JoystickInput.x


func _on_idle_state_physics_processing(delta):
	updateStateTimer()
	CheckButtons()
	if !is_on_floor():
		velocity.y -= GRAVITY
	var midpoint = $"../../Stage/CameraController/BGCamera".global_position.x
	var e = self.global_position.x - midpoint
	var DistToMidpoint = abs(e)
	var tempSpeed = SPEED
	if AllowMovementInput:
		if FacingDir != JoystickInput.x && DistToMidpoint >= maxDistance:
			tempSpeed = 0
		velocity.x = move_toward(velocity.x,JoystickInput.x * tempSpeed,SPEED/ACCEL)

func _on_crouch_state_physics_processing(delta):
	CheckButtons()
	velocity.x = move_toward(velocity.x,0,SPEED/ACCEL)


func _on_jump_squat_state_physics_processing(delta):
	updateStateTimer()
	CheckButtons()
	velocity.x = move_toward(velocity.x,0,SPEED/ACCEL)
	if StateTimer >= JUMPSQUAT:
		$StateChart.send_event("movement_jump")


func _on_airborne_state_entered():
	resetStateTimer()
	$MeshInstance3D.scale.y = 1
	$MeshInstance3D.position.y = 1



func _on_airborne_state_physics_processing(delta):
	updateStateTimer()
	CheckButtons()
	velocity.y -= GRAVITY
	var midpoint = $"../../Stage/CameraController/BGCamera".global_position.x
	var e = self.global_position.x - midpoint
	var DistToMidpoint = abs(e)
	var tempSpeed = SPEED
	
	if FacingDir != AirButtonStorage && DistToMidpoint >= maxDistance:
			tempSpeed = 0
	velocity.x = move_toward(velocity.x,AirButtonStorage * tempSpeed,SPEED/ACCEL)
	if is_on_floor():
		$StateChart.send_event("movement_idle")
		
func _on_airborne_state_exited():
	CurrentAirSpecials = MaxAirSpecials

func _on_hitstun_state_entered():
	resetStateTimer()
	AllowMovementInput = false
	velocity.x = 0
	velocity.y = 0


func _on_hitstun_state_physics_processing(delta):
	updateStateTimer()
	if hitstun == 0:
		AllowMovementInput = true
		if is_on_floor():
			$StateChart.send_event("movement_idle")
		else:
			$StateChart.send_event("movement_airborne")
	elif hitstun > 0:
		hitstun -= 1
	else:
		hitstun = 0



func _on_neutral_state_entered():
	AttackStateTimer = 0 # Replace with function body.

func _on_neutral_state_exited():
	$StateChart.send_event("cancel_jumpsquat")


func _on_attack_a_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Attack A")
	
	
func _on_attack_a_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 5:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true

func _on_attack_ja_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Attack Jump A")


func _on_attack_ja_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 5:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true



func _on_attack_b_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Attack B")


func _on_attack_b_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 5:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true

func _on_attack_c_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Attack C")


func _on_attack_c_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 5:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true
	
func _on_attack_d_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Attack D")


func _on_attack_d_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 5:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true

func _on_attack_6a_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Attack 6A")


func _on_attack_6a_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 5:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true


func _on_attack_j_2b_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Attack Jump 2B")


func _on_attack_j_2b_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 5:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true


func _on_special_236a_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Special 236A")



func _on_special_236a_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_projectile(1,0,Vector3(0.5,1,0))
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true

func _on_special_j_236a_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	CurrentAirSpecials -= 1
	print("Special Jump 236A")


func _on_special_j_236a_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_projectile(1,-0.5,Vector3(0.5,1,0))
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true

func _on_special_214a_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Special 214A")


func _on_special_214a_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer >= 15 && AttackStateTimer <= 19:
		if ButtonAPressed && CheckMotion("214"):
			$StateChart.send_event("input_214a_2")
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true

func _on_followup_214a_236a_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Followup 214A 236A")


func _on_followup_214a_236a_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true


func _on_special_63214b_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Special 63214B")


func _on_special_63214b_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true


func _on_special_4x_6b_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Special [4]6B")


func _on_special_4x_6b_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true


func _on_special_2x_8b_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Special [2]8B")


func _on_special_2x_8b_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true


func _on_special_623c_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Special 623C")


func _on_special_623c_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true


func _on_special_41236c_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Special 41236C")


func _on_special_41236c_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true


func _on_special_22d_state_entered():
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Special 22D")


func _on_special_22d_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true
		

func _on_super_236236a_state_entered():
	spend_meter(100)
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Super 236236A")


func _on_super_236236a_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true


func _on_super_214214a_state_entered():
	build_meter(-100)
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Super 214214A")


func _on_super_214214a_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true


func _on_super_4x_646b_state_entered():
	build_meter(-100)
	AttackStateTimer = 0
	AllowMovementInput = false
	print("Super [4]646B")


func _on_super_4x_646b_state_physics_processing(delta):
	AttackStateTimer += 1
	if AttackStateTimer == 10:
		create_hitbox(3,2,0.5,10,Vector3(0.75,1.25,0),5,20,5,2)
	if AttackStateTimer == 20:
		$StateChart.send_event("attack_neutral_return")
		AllowMovementInput = true

func _on_hitstun_state_exited():
	pass # Replace with function body.


func _on_push_box_area_entered(area):
	print("Pushbox Overlap Detected")
	var parent = area.get_parent()
	var distance = abs(P1Identifier.global_position.x - P2Identifier.global_position.x)
	if !parent.InputLeftPressed && !parent.InputRightPressed:
		parent.velocity.x = (SPEED + 1.55) * FacingDir
	$PushBox.position.z = FacingDir


func _on_push_box_area_exited(area):
	var parent = area.get_parent()
	if $PushBox.global_position.z != 0:
		$PushBox.global_position.z = 0
