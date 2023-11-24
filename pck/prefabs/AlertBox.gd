extends Sprite

export var targetY : float = 0
export var delay : float = 3
var show : bool = false
var tick : float = 0
var wait : float = 0
var x = 1000
var bottomY = 980

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	tick += delta
	if tick > wait :
		show = false
	
	var target = Vector2(x, targetY)
	var bottom = Vector2(x, bottomY)
	if show :
		position = position.linear_interpolate(target, delta*5)
	else :
		position = position.linear_interpolate(bottom, delta*5)

func _show(msg:String):
	$Label.text = msg
	show = true
	wait = tick + delay
	
