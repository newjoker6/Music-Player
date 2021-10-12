extends Control


onready var AudioPlayer = $AudioStreamPlayer
onready var TrackLength = $TrackLength
onready var CurrentPlayback = $CurrentPlayback
onready var VolumeSlider = $Volume/VolumeSlider
onready var PlayBackSlider = $PlayBackSlider
onready var Playlist = $Playlist


#var visualizer01 = load("res://Visualizer.gd")


var stream

var lowpass
var lowshelf

var songlist = []
var currentsong = ""
var currentsongidx = 0
var songplay = ""

var currenttime
var currentmin = 0
var currentsec = 0

var StartingDB = -20

var loop = false



func _ready():
	add_options()
	$ColorPicker.color = Color.green
	

	
	VolumeSlider.value = StartingDB
	AudioPlayer.volume_db = StartingDB
	
#	lowpass = AudioServer.get_bus_effect(0, 0)
#	lowshelf = AudioServer.get_bus_effect(0, 1)
#
#	lowpass.set_cutoff(1000.0)
#	lowshelf.set_cutoff(1000.0)
#
#	print(lowpass.get_cutoff())
#	print(lowshelf.get_cutoff())



func _unhandled_key_input(event):
	if Input.is_key_pressed(KEY_DELETE):
		songlist.remove(currentsongidx)
		Playlist.remove_item(currentsongidx)



func _process(delta):
	if AudioPlayer.is_playing():
		currenttime = int(AudioPlayer.get_playback_position())
		calc_time()
		
		PlayBackSlider.value = currenttime
	


func calc_time():
	if currenttime >= 60:
		currentmin = int(currenttime/60)
		currentsec = currenttime - (currentmin * 60)
	else:
		currentmin = 0
		currentsec = currenttime
	DisplayCurrentTime()



func DisplayCurrentTime():
	if currentsec < 10:
		CurrentPlayback.text = "%s:0%s" %[currentmin, currentsec]
	else:
		CurrentPlayback.text = "%s:%s" %[currentmin, currentsec]



func play_button():
	if songplay != currentsong:
		PlaySong()
		$Button.text = "Pause"
		
	elif AudioPlayer.is_playing() and currentsong == songplay:
		PauseMusic()
		$Button.text = "Play"



func PlaySong():
	
	yield(get_tree(),"idle_frame")
	var file = File.new()
	file.open(songplay, file.READ)
	yield(get_tree(),"idle_frame")
	var buffer = file.get_buffer(file.get_len())

	if songplay.ends_with(".wav"):
		stream = AudioStreamSample.new()
		for i in range(0, 100):
			var those4bytes = str(char(buffer[i])+char(buffer[i+1])+char(buffer[i+2])+char(buffer[i+3]))
			if those4bytes == "RIFF":
				print ("RIFF OK at bytes " + str(i) + "-" + str(i+3))
			if those4bytes == "WAVE":
				print ("WAVE OK at bytes " + str(i) + "-" + str(i+3))
			if those4bytes == "fmt ":
				print ("fmt OK at bytes " + str(i) + "-" + str(i+3))
				var formatsubchunksize = buffer[i+4] + (buffer[i+5] << 8) + (buffer[i+6] << 16) + (buffer[i+7] << 24)
				print ("Format subchunk size: " + str(formatsubchunksize))
				var fsc0 = i+8
				var format_code = buffer[fsc0] + (buffer[fsc0+1] << 8)
				var format_name
				if format_code == 0: format_name = "8_BITS"
				elif format_code == 1: format_name = "16_BITS"
				elif format_code == 2: format_name = "IMA_ADPCM"
				print ("Format: " + str(format_code) + " " + format_name)
				stream.format = format_code
				var channel_num = buffer[fsc0+2] + (buffer[fsc0+3] << 8)
				print ("Number of channels: " + str(channel_num))
				if channel_num == 2:
					stream.stereo = true
				var sample_rate = buffer[fsc0+4] + (buffer[fsc0+5] << 8) + (buffer[fsc0+6] << 16) + (buffer[fsc0+7] << 24)
				print ("Sample rate: " + str(sample_rate))
				stream.mix_rate = sample_rate
				var byte_rate = buffer[fsc0+8] + (buffer[fsc0+9] << 8) + (buffer[fsc0+10] << 16) + (buffer[fsc0+11] << 24)
				print ("Byte rate: " + str(byte_rate))
				var bits_sample_channel = buffer[fsc0+12] + (buffer[fsc0+13] << 8)
				print ("BitsPerSample * Channel / 8: " + str(bits_sample_channel))
				var bits_per_sample = buffer[fsc0+14] + (buffer[fsc0+15] << 8)
				print ("Bits per sample: " + str(bits_per_sample))
			
			if those4bytes == "data":
				var audio_data_size = buffer[i+4] + (buffer[i+5] << 8) + (buffer[i+6] << 16) + (buffer[i+7] << 24)
				print ("Audio data/stream size is " + str(audio_data_size) + " bytes")

				var data_entry_point = (i+8)
				print ("Audio data starts at byte " + str(data_entry_point))
				
				stream.data = buffer.subarray(data_entry_point, data_entry_point+audio_data_size-1)
		
		var samplenum = stream.data.size() / 4
		for i in 80:
			buffer.remove(buffer.size()-1)
			buffer.remove(0)
		stream.data = buffer
		AudioPlayer.stream = stream
		AudioPlayer.set_stream_paused(false)
		AudioPlayer.play()
		
	
	elif songplay.ends_with(".mp3"):
		stream = AudioStreamMP3.new()
		for i in 200:
			buffer.remove(buffer.size()-1)
			buffer.remove(0)
		stream.data = buffer
		AudioPlayer.stream = stream
		AudioPlayer.set_stream_paused(false)
		AudioPlayer.play()
		
	elif songplay.ends_with(".ogg"):
		print(songplay)
		stream = AudioStreamOGGVorbis.new()
#		for i in 200:
#			buffer.remove(buffer.size()-1)
#			buffer.remove(0)
		stream.data = buffer
		AudioPlayer.stream = stream
		AudioPlayer.set_stream_paused(false)
		AudioPlayer.play()
	print(60 * (stream.get_length()/60 - int(stream.get_length()/60)))
	printt("Minutes",round(stream.get_length()/60),"Seconds",round(60 * (stream.get_length()/60 - int(stream.get_length()/60))))
	
	var seconds = round(60 * (stream.get_length()/60 - int(stream.get_length()/60)))
	var minutes = round(stream.get_length()/60)
	
	if seconds <= 9:
		TrackLength.text = "%s:0%s" %[minutes, seconds]
	else:
		TrackLength.text = "%s:%s" %[minutes, seconds]
	PlayBackSlider.max_value = stream.get_length()
	file.close()
	currentsong = songplay
	



func PauseMusic():
	if AudioPlayer.get_stream_paused() == false:
		AudioPlayer.set_stream_paused(true)
	elif AudioPlayer.get_stream_paused() == true:
		AudioPlayer.set_stream_paused(false)



func _on_VolumeSlider_value_changed(value):
	AudioPlayer.volume_db = value



func _on_PlayBackSlider_value_changed(value):
	AudioPlayer.seek(value)



func _on_ItemList_item_activated(index):
	songplay = songlist[index]
	currentsongidx = index
	PlaySong()



func _on_ItemList_item_selected(index):
	songplay = songlist[index]
	currentsongidx = index
	print(songplay)
	print(currentsong)



func _on_FileDialog_files_selected(paths):
	var temp_list = paths
	for path in temp_list:
		songlist.append(path)
	for song in temp_list:
		Playlist.add_item(song.get_file().replace(".%s" %song.get_extension(),""))
		print(song.get_file())
	
	if songplay == "":
		Playlist.select(0)
		songplay = songlist[0]
		currentsongidx = 0



func _on_AddSongButton_pressed():
	$FileDialog.popup_exclusive = true
	print(OS.get_system_dir(OS.SYSTEM_DIR_MUSIC))
	$FileDialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_MUSIC) + "/Music"
	$FileDialog.current_path = OS.get_system_dir(OS.SYSTEM_DIR_MUSIC) + "/Music"
	$FileDialog.popup_centered()



func _on_VolumeButton_toggled(button_pressed):
	if $Volume.visible == false:
		$Volume.visible = true
		VolumeSlider.grab_focus()
	else:
		$Volume.visible = false



func _on_StopButton_pressed():
	AudioPlayer.set_stream_paused(true)
	yield(get_tree().create_timer(0.3),"timeout")
	currentsong = ""
	CurrentPlayback.text = "0:00"
	print("reset")
	PlayBackSlider.value = 0
	AudioPlayer.stop()
	$Button.text = "Play"




func _on_PrevButton_pressed():
	if currentsongidx > 0:
		currentsongidx -= 1
		songplay = songlist[currentsongidx]
		PlaySong()
		Playlist.select(currentsongidx)
	else:
		pass



func _on_NextButton_pressed():
	if currentsongidx < songlist.size() - 1:
		currentsongidx += 1
		songplay = songlist[currentsongidx]
		PlaySong()
		Playlist.select(currentsongidx)
	else:
		pass


func _on_ColorPicker_color_changed(color):
	$Visualizers/Visualizer1.color = color
	$Visualizers/Visualizer2.color = color
	$Visualizers/Visualizer3.color = color


func _on_LoopButton_pressed():
	if loop:
		loop = false
		print(loop)
	else:
		loop = true
		print(loop)


func _on_AudioStreamPlayer_finished():
#	_on_NextButton_pressed()
	
#	yield(get_tree().create_timer(0.5),"timeout")
#	currentsongidx += 1
#	songplay = songlist[currentsongidx]
#	PlaySong()
	if loop == true:
		songplay = songlist[currentsongidx]
		PlaySong()

	elif loop == false:
		if currentsongidx < songlist.size() - 1:
			yield(get_tree(),"idle_frame")
			currentsongidx += 1
			yield(get_tree(),"idle_frame")
			songplay = songlist[currentsongidx]
			yield(get_tree(),"idle_frame")
			Playlist.select(currentsongidx)
			yield(get_tree(),"idle_frame")
			print(songplay)
			PlaySong()

		elif currentsongidx == songlist.size() - 1:
			currentsongidx = 0
			songplay = songlist[currentsongidx]
			PlaySong()
			Playlist.select(currentsongidx)

func add_options():
	for i in $Visualizers.get_children():
		$OptionButton.add_item(i.name)
	$OptionButton.select(1)


func _on_OptionButton_item_selected(index):
	var Vis_name = $OptionButton.get_item_text(index)
	for i in $Visualizers.get_children():
		print(i.name)
		get_node("Visualizers/%s" %i.name).visible = false
	get_node("Visualizers/%s" %Vis_name).visible = true
	
