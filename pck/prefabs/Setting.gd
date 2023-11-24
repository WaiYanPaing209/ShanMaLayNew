extends Panel


var filepath = "user://setting.txt"

func _ready():
	var file = File.new()
	if file.file_exists(filepath):
		file.open(filepath, File.READ)
		var data = file.get_as_text()
		var obj = JSON.parse(data)
		file.close()
		var effectVol = obj.result.effect
		var musicVol = obj.result.music 
		$SliderEffect.value = effectVol
		$SliderMusic.value = musicVol
		AudioServer.set_bus_volume_db(1,effectVol)
		AudioServer.set_bus_volume_db(2,musicVol)
	
	var canvas_rid = get_canvas_item()
	# You may need to adjust these values
	VisualServer.canvas_item_set_draw_index(canvas_rid,100)
	VisualServer.canvas_item_set_z_index(canvas_rid,100)


func _save(data):
	var file = File.new()
	file.open(filepath, File.WRITE)
	file.store_string(JSON.print(data))
	file.close()


func _show():
	$AnimationPlayer.play("show")


func _hide():
	$AnimationPlayer.play("hide")


func _on_Submit_pressed():
	_hide()
	var data = {
		"music":$SliderMusic.value,
		"effect":$SliderEffect.value
	}
	_save(data)


func _on_SliderMusic_value_changed(value):
	AudioServer.set_bus_volume_db(2,value)


func _on_SliderEffect_value_changed(value):
	AudioServer.set_bus_volume_db(1,value)




func _on_Submit_mouse_entered():
	$Submit.rect_scale = Vector2(1.1,1.1)


func _on_Submit_mouse_exited():
	$Submit.rect_scale = Vector2(1,1)
