extends AnimatedSprite

export var no = 0
export var speed = 500
var target 


# Called when the node enters the scene tree for the first time.
func _ready():
	target = position


func _process(delta):
	position = position.move_toward(target,delta*speed)
