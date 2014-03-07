extends RigidBody2D

# Character Demo, written by Juan Linietsky.
#
# Implementation of a 2D Character controller.
# This implementation uses the physics engine for
# controlling a character, in a very similar way
# than a 3D character controller would be implemented.
#
# Using the physics engine for this has the main
# advantages:
# -Easy to write.
# -Interaction with other physics-based objects is free
# -Only have to deal with the object linear velocity, not position
# -All collision/area framework available
# 
# But also has the following disadvantages:
#  
# -Objects may bounce a little bit sometimes
# -Going up ramps sends the chracter flying up, small hack is needed.
# -A ray collider is needed to avoid sliding down on ramps and  
#   undesiderd bumps, small steps and rare numerical precision errors.
#   (another alternative may be to turn on friction when the character is not moving).
# -Friction cant be used, so floor velocity must be considered
#  for moving platforms.

var anim=""
var siding_left=false
var jumping=false
var stopping_jump=false
var shooting=false
var swording=false
var paused=false

var WALK_ACCEL = 800.0
var WALK_DEACCEL= 19000.0
var WALK_MAX_VELOCITY= 200.0
var GRAVITY = 900.0
var AIR_ACCEL = 200.0
var AIR_DEACCEL= 200.0
var JUMP_VELOCITY=460
var STOP_JUMP_FORCE=900.0

var MAX_FLOOR_AIRBORNE_TIME = 0.15

var airborne_time=1e20

var shoot_time=1e20
var bullettime = 1
var bullet = preload("res://bullet.xml")
var sword_time=1e20
var MAX_SHOOT_POSE_TIME = 0.3
var MAX_SWORD_POSE_TIME = 0.3

var floor_h_velocity=0.0
#var enemy

func _integrate_forces(s):

	var lv = s.get_linear_velocity()
	var step = s.get_step()
	
	var new_anim=anim
	var new_siding_left=siding_left
	
	# Get the controls
	var move_left = Input.is_action_pressed("move_left")
	var move_right = Input.is_action_pressed("move_right")
	var jump = Input.is_action_pressed("jump")
	var atack_1 = Input.is_action_pressed("atack_1")
	var atack_2 = Input.is_action_pressed("atack_2")
#	var pause = Input.is_action_pressed("pause")
	
	#deapply prev floor velocity
	lv.x-=floor_h_velocity
	floor_h_velocity=0.0
	
	
	# Find the floor (a contact with upwards facing collision normal)
	var found_floor=false
	var floor_index=-1
	
	for x in range(s.get_contact_count()):

		var ci = s.get_contact_local_normal(x)
		if (ci.dot(Vector2(0,-1))>0.6):
			found_floor=true
			floor_index=x

##Shooting
	if (atack_2 and not shooting and found_floor==true and move_left==0 and move_right==0):
		shoot_time=0
		var bi = bullet.instance()
		var ss
		if (siding_left):
			ss=-1.7
		else:
			ss=1.7
		var pos = get_pos() + get_node("bullet_shoot").get_pos()*Vector2(ss,1.0)

		bi.set_pos(pos)
		get_parent().add_child(bi)

		bi.set_linear_velocity( Vector2(800.0*ss,-80) )	
		
#		var bums = get_wait_time("bullettime")
#		if (bums == 0):
#			var time
#		sleep(0.3)
		get_node("sprite/smoke").set_emitting(true)	
#		get_node("sound").play("shoot")
		PS2D.body_add_collision_exception(bi.get_rid(),get_rid()) # make bullet and this not collide



	else:
		shoot_time+=step
	
	shooting = atack_2


	if (found_floor):
		airborne_time=0.0 
	else:
		airborne_time+=step #time it spent in the air
		
	var on_floor = airborne_time < MAX_FLOOR_AIRBORNE_TIME

	# Process jump		
	if (jumping):
		if (lv.y>0):
			#set off the jumping flag if going down
			jumping=false
		elif (not jump):
			stopping_jump=true
			
		if (stopping_jump):
			lv.y+=STOP_JUMP_FORCE*step
		
	if (on_floor):

		# Process logic when character is on floor
			
		if (move_left and not move_right):
			if (lv.x > -WALK_MAX_VELOCITY):
				lv.x-=WALK_ACCEL*step			
		elif (move_right and not move_left):
			if (lv.x < WALK_MAX_VELOCITY):
				lv.x+=WALK_ACCEL*step
		else:
			var xv = abs(lv.x)
			xv-=WALK_DEACCEL*step
			if (xv<0):
				xv=0
			lv.x=sign(lv.x)*xv
			
		#Check jump
		if (not jumping and jump):
			lv.y=-JUMP_VELOCITY
			jumping=true
			stopping_jump=false
			
		#check siding
		
		if (lv.x < 0 and move_left):
			new_siding_left=true
		elif (lv.x > 0 and move_right):
			new_siding_left=false
		if (jumping):
			new_anim="jumping"	
		elif (abs(lv.x)<0.1):
			if (shoot_time<MAX_SHOOT_POSE_TIME):	
				new_anim="idle_weapon"
			else:
				new_anim="idle"
		else:
			new_anim="run"
	else:
	
		# Process logic when the character is in the air
		
		if (move_left and not move_right):
			if (lv.x > -WALK_MAX_VELOCITY):
				lv.x-=AIR_ACCEL*step			
		elif (move_right and not move_left):
			if (lv.x < WALK_MAX_VELOCITY):
				lv.x+=AIR_ACCEL*step
		else:
			var xv = abs(lv.x)
			xv-=AIR_DEACCEL*step
			if (xv<0):
				xv=0
			lv.x=sign(lv.x)*xv
			
		if (lv.y<0):
			new_anim="jumping"
		else:
			new_anim="falling"
		

	#Update siding
	
	if (new_siding_left!=siding_left):
		if (new_siding_left):
			get_node("sprite").set_scale( Vector2(-1,1) )
		else:
			get_node("sprite").set_scale( Vector2(1,1) )
			
		siding_left=new_siding_left
							
	#Change animation
	if (new_anim!=anim):
		anim=new_anim
		get_node("anim").play(anim)
		

		
	# Apply floor velocity
	if (found_floor):
		floor_h_velocity=s.get_contact_collider_velocity_at_pos(floor_index).x
		lv.x+=floor_h_velocity
	
	#Finally, apply gravity and set back the linear velocity
	lv+=s.get_total_gravity()*step
	s.set_linear_velocity(lv)
	
	if (Input.is_action_pressed("exit")):
		OS.get_main_loop().quit()
	
	if (Input.is_action_pressed("pause") and paused==false):
#		set_pause(200)
		get_node("ui/pause_popup").set_exclusive(true)
		get_node("ui/pause_popup").popup()
		get_scene().set_pause(true)
		paused=true

	elif (Input.is_action_pressed("pause") and paused==true):
		get_node("ui/pause_popup").hide()
		get_scene().set_pause(false)
		paused=false
	
func _on_unpause_pressed():
	get_node("ui/pause_popup").hide()
	get_scene().set_pause(false)

func _ready():
	# Initalization here
	pass



