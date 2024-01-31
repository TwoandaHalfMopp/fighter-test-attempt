extends Control
var P1MaxHealth
var P1CurrentHealth
var P2MaxHealth
var P2CurrentHealth

var P1MaxSuper
var P1CurrentSuper
var P2MaxSuper
var P2CurrentSuper

@onready var p1 = $"../../P1Character".get_child(0)
@onready var p2 = $"../../P2Character".get_child(0)

@onready var P1HealthBar = $P1HealthBar
@onready var P2HealthBar = $P2HealthBar
@onready var P1HealthLabel = $P1HealthLabel
@onready var P2HealthLabel = $P2HealthLabel
@onready var P1SuperBar = $P1SuperBar
@onready var P2SuperBar = $P2SuperBar
@onready var P1SuperLabel = $P1SuperLabel
@onready var P2SuperLabel = $P2SuperLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	P1MaxHealth = p1.MaxHealth
	P1HealthBar.max_value = P1MaxHealth
	P1HealthBar.min_value = 0
	P1MaxSuper = p1.MaxSuper
	P1SuperBar.max_value = P1MaxSuper
	P1SuperBar.min_value = 0
	
	P2MaxHealth = p2.MaxHealth
	P2HealthBar.max_value = P2MaxHealth
	P2HealthBar.min_value = 0
	P2MaxSuper = p2.MaxSuper
	P2SuperBar.max_value = P2MaxSuper
	P2SuperBar.min_value = 0
	updateBars()
	
	
	

func updateBars():
	P1CurrentHealth = p1.CurrentHealth
	P2CurrentHealth = p2.CurrentHealth
	P1CurrentSuper = p1.CurrentSuper
	P2CurrentSuper = p2.CurrentSuper
	
	

	P1HealthBar.value = P1CurrentHealth
	P1HealthLabel.text = str(P1CurrentHealth," ")
	
	P2HealthBar.value = P2CurrentHealth
	P2HealthLabel.text = str(" ",P2CurrentHealth)
	
	P1SuperBar.value = P1CurrentSuper
	P1SuperLabel.text = str(P1CurrentSuper," ")
	
	P2SuperBar.value = P2CurrentSuper
	P2SuperLabel.text = str(" ",P2CurrentSuper)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	updateBars()
