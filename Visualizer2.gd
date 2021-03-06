extends Node2D


var spectrum = AudioServer.get_bus_effect_instance(0,0)
var definition = 20
var total_w = 400
var total_h = 200
var min_freq = 20
var max_freq = 20000

var max_db = 60
var min_db = -10


var accel = 20
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
		
		var mag = spectrum.get_magnitude_for_frequency_range(freqrange_low, freqrange_high)
		mag = linear2db(mag.length())
		mag = (mag - min_db) / (max_db - min_db)
		
		mag += 0.3 * (freq - min_freq) / (max_freq - min_freq)
		mag = clamp(mag, 0.05, 1)
		histogram[i] = lerp(histogram[i], mag, accel * delta)
		
		
	
	update()

func _draw():
	var draw_pos = Vector2(0,0)
	var w_interval = total_w / definition
	draw_line(Vector2(0, -total_h), Vector2(total_w, -total_h), color, 2.0, true)
	
	for i in range(definition):
		draw_line(draw_pos, draw_pos + Vector2(0, -histogram[i] * total_h), color, 4.0, true)
		draw_pos.x += w_interval
