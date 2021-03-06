extends Node2D


var spectrum = AudioServer.get_bus_effect_instance(0,0)
var definition = 20
var total_w = 400
var total_h = 200
var min_freq = 20
var max_freq = 20000

var max_db = 90
var min_db = -80

var accel = 30
var histogram = []
var color = Color("3F985D")

func _ready():
	max_db += get_parent().get_parent().get_node("AudioStreamPlayer").volume_db
	min_db += get_parent().get_parent().get_node("AudioStreamPlayer").volume_db
	
	for i in range(definition):
		histogram.append(0)

func _process(delta):
	var freq = min_freq
	var interval = (max_freq - min_freq) / definition
	
	for i in range(definition):
		
		var freqrange_low = float(freq - min_freq) / float(max_freq - min_freq)
		freqrange_low = pow(freqrange_low, 6)
		freqrange_low = lerp(min_freq, max_freq, freqrange_low)
		
		freq += interval
		
		var freqrange_high = float(freq - min_freq) / float(max_freq - min_freq)
		freqrange_high = pow(freqrange_high, 6)
		freqrange_high = lerp(min_freq, max_freq, freqrange_high)
		
		var mag = spectrum. get_magnitude_for_frequency_range(freqrange_low, freqrange_high)
		mag = linear2db(mag.length())
		mag = (mag - min_db) / (max_db - min_db)
		
		mag += 0.3 * (freq - min_freq) / (max_freq - min_freq)
		mag = clamp(mag, 0.05, 1)
		histogram[i] = lerp(histogram[i], mag, accel * delta)
		
		
	
	update()

func _draw():
	var angle = PI
	var angle_interval = 2 * PI / definition
	var radius = 50
	var length = 50
	
	for i in range(definition):
		var normal = Vector2(0, -1).rotated(angle)
		var start_pos = normal * radius
		var end_pos = normal * (radius + histogram[i] * length)
		draw_line(start_pos, end_pos + Vector2(0, -histogram[i] * total_h), color, 4.0, true)
		angle += angle_interval
