extends Panel
 
# member variables here, example:
# var a=2
# var b="textvar"
 
func _on_button_pressed():
	get_node("Label").set_text("HELLO!")
 
func _ready():
	get_node("Button").connect("pressed",self,"_on_button_pressed")