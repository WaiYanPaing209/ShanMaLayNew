extends Sprite

export var speed = 1000
# -2 - nobody, -1 - dealer, 0 to 7 - player
var playerIndex = -2
var target = Vector2(0,0)
var destroyOnArrive = false
var textures = [
	preload("res://pck/assets/common/play-coin-1.png"),
	preload("res://pck/assets/common/play-coin-2.png"),
	preload("res://pck/assets/common/play-coin-3.png")
]

# Called when the node enters the scene tree for the first time.
func _ready():
	var r = randi()%textures.size()
	texture = textures[r]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = position.move_toward(target,delta*speed)
	if destroyOnArrive == true :
		if position == target :
			queue_free()
