extends Sprite

export var speed = 2000
var target = Vector2(1000,220)
var card = null
var movable = true
var destroyOnArrive = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if movable:
		position = position.move_toward(target,delta*speed)
		if destroyOnArrive == true :
			if position == target :
				queue_free()

func _set_card(_card):
	card = _card

func _highlight():
	$AnimationPlayer.play("highlight")

func _point_card():
	$MoneyCard.visible = true
