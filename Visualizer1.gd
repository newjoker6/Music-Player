extends Node2D


const vu_count = 128
const freq_max = 10000.0
const max_height = 256
const max_radius_small = 16

const min_db = 100

var prev_energy = []
var prev_small_radius = 0

var spectrum

var color = Color("3F985D")

func _ready():
	prev_energy.resize(vu_count)
	for i in range(prev_energy.size()):
		prev_energy[i] = 0
	spectrum = AudioServer.get_bus_effect_instance(0,0)


func _process(delta):
	update()


# Called when the node enters the scene tree for the first time.
func _draw():
	var angle = (2 * PI) / vu_count
	var prev_hz = 0
	var magnitude_full_db = spectrum.get_magnitude_for_frequency_range(0, 15000).length()
	var energy_volume = clamp((min_db + linear2db(magnitude_full_db)) / min_db, 0, 1)
	rotation_degrees = get_parent().get_parent().get_node("AudioStreamPlayer").get_playback_position() * 5
	
	var small_radius = (max_radius_small/2) * (8 * energy_volume)
	if small_radius < prev_small_radius:
		small_radius = prev_small_radius - 0.2
	
	prev_small_radius = small_radius
	
	for i in range(vu_count):
		var hz = (i + 1) * freq_max / vu_count
		var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy = clamp((min_db + linear2db(magnitude)) / min_db, 0, 1)
		if energy < prev_energy[i]:
			energy = prev_energy[i] - 0.01
		prev_energy[i] = energy
		
		var vec = Vector2(sin(i * angle), -cos(i * angle))
		var pos_start = vec * small_radius
		var pos_end = vec * (small_radius + energy * max_height)
		
		draw_line(pos_start, pos_end, color, 3, true)
		
		prev_hz = hz
