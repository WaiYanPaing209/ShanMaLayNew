extends Sprite

export var speed = 500
var target = Vector2(1000,450)

# Called when the node enters the scene tree for the first time.
func _ready():
	target = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = position.move_toward(target,delta*speed)
