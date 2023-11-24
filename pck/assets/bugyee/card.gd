extends Sprite

export var speed = 2000
var target = Vector2(1000,220)
var originalScale

# Called when the node enters the scene tree for the first time.
func _ready():
	originalScale = scale


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = position.move_toward(target,delta*speed)

func _highlight():
	scale = originalScale * 1.2
	z_index = 1

func _unhighlight():
	scale = originalScale
	z_index = 0
