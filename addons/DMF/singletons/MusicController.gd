extends Node

"""
	Track and Midi Player Singleton by Nino Candrlic @R3X_G1L6AME5H
"""

const SMF = preload("res://addons/DMF/singletons/SMF.gd")
export (String, FILE, "*.tres") var path_to_song_library = "res://Library.tres"
var SONG_LIBRARY : Dictionary

## Used for tracking time, an AudioPlayer being the most precise method 
onready var clock = $SyncPlayer
var clock_offset : float = 0.0
var position : float = 0

#### TRACKS ####
var current_song = ""
var bar_length : float
var current_players = []
var current_oneshots = []
var current_segment = ""
var current_segment_start : float
var current_segment_end   : float
var watchdog_curves = []
var is_playing = true

class Player extends AudioStreamPlayer:
	var start_time : float
	var end_time : float
	var trigger_chance : float

#### MIDI ####
var midi_statuses = {}
var midi_enabled = false
var notes_on = {}
signal note_on ( channel, note )
signal note_off( channel, note )

class GodotMIDIPlayerTrackStatus:
	var playing       : bool  = false
	var type          : bool  = 0  
		### 0 - behaviour
		### 1 - pitch correction
	var notes_owned   : Dictionary = {}
	var events        : Array = []
	var event_pointer : int   = 0
	var timebase      : float = 0
	var start_time    : float
	var end_time      : float


#####################################################################################
func _ready():
	var file = File.new()
	file.open(path_to_song_library, File.READ)
	SONG_LIBRARY = file.get_var()
	file.close()
	
	start_song("SONG")

"""
Go through all tracks in this song and create players for it.
"""
func _init_song() -> void:
	#### CREATE ALL PLAYERS
	for track in SONG_LIBRARY[current_song]["tracks"].keys():
		var player = Player.new()
		player.name = track
		player.start_time = SONG_LIBRARY[current_song]["tracks"][track]["start"] * bar_length
		player.end_time = SONG_LIBRARY[current_song]["tracks"][track]["end"] * bar_length
		
		### add mechanism for start offsets
		
		player.stream = load( SONG_LIBRARY[current_song]["tracks"][track]["path"] )
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1, track)
		AudioServer.set_bus_send(AudioServer.get_bus_index(track), "Maestro")
		player.bus = track
		add_child(player)                 ### Remove with queue_free on current_players array
		current_players.append(player)
	
	#### CREATE ONESHOTS
	for oneshot in SONG_LIBRARY[current_song]["oneshots"]:
		var player = Player.new()
		player.name = "OS"
		player.start_time = oneshot.start * bar_length
		player.stream = load(oneshot.path)
		player.trigger_chance = oneshot.chance
		player.bus = "Oneshots"
		current_oneshots.append(player)
		self.add_child(player)
	
	#### CONSTRUCT WATCHDOG CURVES
	for watchdog in SONG_LIBRARY[current_song].watchdogs:
		var crv = Curve.new()
		for idx in range(watchdog.graph.pos.size()):
			crv.add_point(  Vector2(watchdog.graph.pos[idx][0], watchdog.graph.pos[idx][1]),
							watchdog.graph.tg[idx][0],
							watchdog.graph.tg[idx][1],
							watchdog.graph.tgm[idx] & 1,
							watchdog.graph.tgm[idx] & 2)
		crv.bake()
		watchdog_curves.append(crv)
	
	
	#### SEGMENT CONTROL
	current_segment_start = SONG_LIBRARY[current_song]["segments"][current_segment]["start"] * bar_length
	current_segment_end   = SONG_LIBRARY[current_song]["segments"][current_segment]["end"] * bar_length
	
	for player in current_players:
		if player.start_time == 0:
			player.playing = true
	
	clock.play()

"""
Go through all midis in this song and create players for it.
"""
func _init_midi( ) -> void:
	if SONG_LIBRARY[current_song]["midis"].empty():
		midi_enabled = false
		return
	
	midi_enabled = true
	var smf = SMF.new()
	for track_key in SONG_LIBRARY[current_song]["midis"].keys():
		var midi_data = smf.read_file( SONG_LIBRARY[current_song]["midis"][track_key].midi )
		if midi_data == null:
			push_error("Can't load " + SONG_LIBRARY[current_song]["midis"][track_key].midi + ".")
			continue
		
		midi_statuses[track_key] = GodotMIDIPlayerTrackStatus.new( )
		
		midi_statuses[track_key].event_pointer = 0
		
		if len( midi_data.tracks ) == 1:
			midi_statuses[track_key].events = midi_data.tracks[0].events
		else:
			# Mix multiple tracks to single track
			var tracks:Array = []
			var track_id:int = 0
			for track in midi_data.tracks:
				tracks.append({"track_id": track_id, "pointer":0, "events":track.events, "length": len( track.events )})
				track_id += 1
		
			var time:int = 0
			var finished:bool = false
			while not finished:
				finished = true
		
				var next_time:int = 0x7fffffff
				for track in tracks:
					var p = track.pointer
					if track.length <= p: continue
					finished = false
				
					var e : SMF.MIDIEventChunk = track.events[p]
					var e_time:int = e.time
					if e_time == time:
						midi_statuses[track_key].events.append( e )
						track.pointer += 1
						next_time = e_time
					elif e_time < next_time:
						next_time = e_time
				time = next_time
	
		midi_statuses[track_key].event_pointer = 0
		midi_statuses[track_key].timebase      = midi_data.timebase
		midi_statuses[track_key].type          = SONG_LIBRARY[current_song]["midis"][track_key]["pitch"]
		midi_statuses[track_key].start_time    = SONG_LIBRARY[current_song]["midis"][track_key]["start"] * bar_length
		midi_statuses[track_key].end_time      = SONG_LIBRARY[current_song]["midis"][track_key]["end"] * bar_length

######################################################################################
func _process(delta):
	if is_playing:
		### CHECK SEGMENT
		if current_segment_end - delta*2.0 < position:
			for transition in SONG_LIBRARY[current_song].segments[current_segment].transitions:
				var tmp = float(Blackboard.get(transition.current)) / float(Blackboard.get(transition.max))
				if transition.floor <= tmp and tmp <= transition.ceil:
					current_segment       = transition.target
					current_segment_start = SONG_LIBRARY[current_song]["segments"][current_segment]["start"] * bar_length
					current_segment_end   = SONG_LIBRARY[current_song]["segments"][current_segment]["end"] * bar_length
				
			seek(current_segment_start)
		
		## KEEP TRACK OF TIME
		position = clock.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() + clock_offset
		
		_process_tracks()
		_process_watchdogs()
		_process_oneshots(delta)
		if midi_enabled: _process_midi()

"""
Control when to toggle players.
"""
func _process_tracks() -> void:
	### TURN ON/OF PLAYERS
	for player in current_players:
		if player.start_time < position and not player.playing:
			player.seek(position - player.start_time)
			player.playing = true
		elif player.end_time < position and player.playing:
			player.playing = false

"""
Check how the stats that the watchdogs observe change, 
and apply the change to a bus property.
"""
func _process_watchdogs() -> void:
	## CHECK ON WATCHDOGS
	for idx in range(SONG_LIBRARY[current_song].watchdogs.size()):
		var bus_id = AudioServer.get_bus_index( SONG_LIBRARY[current_song].watchdogs[idx].track )
		if Blackboard.has(SONG_LIBRARY[current_song].watchdogs[idx].current) and Blackboard.has(SONG_LIBRARY[current_song].watchdogs[idx].max):
			var value = watchdog_curves[idx].interpolate_baked(
							clamp(  float(Blackboard.get(SONG_LIBRARY[current_song].watchdogs[idx].current)) / \
									float(Blackboard.get(SONG_LIBRARY[current_song].watchdogs[idx].max)) ,\
							0, \
							1) \
						)
			match (SONG_LIBRARY[current_song].watchdogs[idx].target):
				"VOL":
					AudioServer.set_bus_volume_db(bus_id, value)

"""
Roll the dice to see if an oneshot should be played.
"""
func _process_oneshots( delta : float ) -> void:
	## CHECK ON ONESHOTS
	for oneshot in current_oneshots:
		if position > oneshot.start_time and position < oneshot.start_time + delta * 2:
			#prints("Triggered", oneshot.trigger_chance)
			if randf() <= oneshot.trigger_chance:
				oneshot.play()

"""
Emit signals when notes are on/off, given that the triggers are satisfied.
"""
func _process_midi() -> void:
	for stat_key in  midi_statuses.keys():
		if midi_statuses[stat_key].start_time < position and not midi_statuses[stat_key].playing:
			midi_statuses[stat_key].playing = true
			_midi_seek( position - midi_statuses[stat_key].start_time, stat_key )
		elif midi_statuses[stat_key].end_time < position and midi_statuses[stat_key].playing:
			midi_statuses[stat_key].playing = false
		
		if not midi_statuses[stat_key].playing:
			continue
		# seek_time < midi_statuses[stat_key].end_time:
		
		var length : int = len( midi_statuses[stat_key].events )
		if length <= midi_statuses[stat_key].event_pointer:
			midi_statuses[stat_key].playing = false
			continue
		#	if self.loop:
		#		var diff:float = self.position - track.events[len( track.events ) - 1].time
		#		self.seek( self.loop_start )
		#		self.emit_signal( "looped" )
		#		self.position += diff
		#	else:
		#		self.playing = false
		#		self.emit_signal( "finished" )
		#	return 0
		
		var current_position : int = int( ceil( \
												position * ((midi_statuses[stat_key].timebase * SONG_LIBRARY[current_song].bpm) / 60.0) \
											) )
		
		while midi_statuses[stat_key].event_pointer < length:
			var event_chunk:SMF.MIDIEventChunk = midi_statuses[stat_key].events[midi_statuses[stat_key].event_pointer]
			if current_position <= event_chunk.time:
				break
			midi_statuses[stat_key].event_pointer += 1
		
			### CHECK IF TRIGGERS ARE SATISFIED
			## A trigger being a range of values that makes the midi play 
			if SONG_LIBRARY[current_song]["midis"][stat_key]["single_trigger"]:
				if Blackboard.get(SONG_LIBRARY[current_song]["midis"][stat_key]["property"]) != SONG_LIBRARY[current_song]["midis"][stat_key]["value"]:
					### CLEAN ALL ACTIVE NOTES
					for note in midi_statuses[stat_key].notes_owned.keys():
						emit_signal("note_off", stat_key, note)
					midi_statuses[stat_key].notes_owned.clear()
					continue
			
			else:
				# No need to check if the enitire trigger range is selected
				if SONG_LIBRARY[current_song]["midis"][stat_key]["floor"] != 0 or SONG_LIBRARY[current_song]["midis"][stat_key]["ceil"] != 1:
					var trigger_value = clamp( \
											float(Blackboard.get(SONG_LIBRARY[current_song]["midis"][stat_key]["current"])) \
											/ float(Blackboard.get(SONG_LIBRARY[current_song]["midis"][stat_key]["max"])), \
											0, 1)
					if SONG_LIBRARY[current_song]["midis"][stat_key]["floor"] >= trigger_value or trigger_value > SONG_LIBRARY[current_song]["midis"][stat_key]["ceil"]:
						### CLEAN ALL ACTIVE NOTES
						for note in midi_statuses[stat_key].notes_owned.keys():
							emit_signal("note_off", stat_key, note)
							notes_on.erase(note)
						midi_statuses[stat_key].notes_owned.clear()
						continue
			
			
			### CHECK FOR NOTES
			var event : SMF.MIDIEvent = event_chunk.event
			
			## HANDLE PITCH CORRECTION TRACK
			if midi_statuses[stat_key].type:
				if event.type == SMF.MIDIEventType.note_on:
					var event_note_on : SMF.MIDIEventNoteOn = event as SMF.MIDIEventNoteOn
					var bus_id = AudioServer.get_bus_index( SONG_LIBRARY[current_song]["midis"][stat_key].bus )
					if bus_id > -1:
						var fx = AudioServer.get_bus_effect(bus_id, SONG_LIBRARY[current_song]["midis"][stat_key].sfx)
						if fx:
							fx.pitch_scale = 1 + (event_note_on.note % 12) / 12.0
			
			## HANDLE BEHAVIOUR TRACK
			else:
				match event.type:
					SMF.MIDIEventType.note_off:
						var event_note_off : int = ( event as SMF.MIDIEventNoteOff ).note
						notes_on.erase(event_note_off)
						midi_statuses[stat_key].notes_owned.erase(event_note_off)
						#printt("OFF", event_note_off )
						emit_signal("note_off", stat_key, event_note_off)
				
					SMF.MIDIEventType.note_on:
						var event_note_on : SMF.MIDIEventNoteOn = event as SMF.MIDIEventNoteOn
						notes_on[event_note_on.note] = event_note_on.velocity
						midi_statuses[stat_key].notes_owned[event_note_on.note] = true
						#printt("ON", event_note_on.note )
						emit_signal("note_on", stat_key, event_note_on)

"""
Move the marker to the the place in a song you want.
Used for transitions, and loops.
"""
func seek( seek_time : float ):
	### CLEAR THE SLATE
	for note in notes_on.keys():
		emit_signal("note_off", note)
	notes_on.clear()
	
	### RESET CLOCK AND UPDATE THE OFFSET
	clock.seek( 0 )    # It will always reset to 0, regardless of the value
	clock_offset = seek_time
	## the clock will always go from 0 to the length of the segment,
	## while the position will mark where in the song the player is playing
	## COULD be useful
	
	### SYNC MIDI AND PLAYBACK
	if midi_enabled:
		for stat_key in midi_statuses.keys():
			if midi_statuses[stat_key].start_time <= seek_time and seek_time < midi_statuses[stat_key].end_time:
				_midi_seek( seek_time - midi_statuses[stat_key].start_time, stat_key )
				midi_statuses[stat_key].notes_owned.clear()
	
	### TOGGLE PLAYERS ACCORDINGLY
	for player in current_players:
		if player.start_time <= seek_time and seek_time < player.end_time:
			if not player.playing:
				player.playing = true
			player.seek( seek_time - player.start_time )
		else:
			player.playing = false

"""
A special function to move the MIDI marker.
"""
func _midi_seek( seek_time : float, track_status_key : String ):
	var current_position = seek_time * ((midi_statuses[track_status_key].timebase * SONG_LIBRARY[current_song].bpm) / 60.0)
	var pointer:int = 0
	var new_position:int = int( floor( current_position ) )
	for event_chunk in midi_statuses[track_status_key].events:
		if new_position <= event_chunk.time:
			break
		pointer += 1
	midi_statuses[track_status_key].event_pointer = pointer

"""
Some control functions
"""
func get_song_list():
	if SONG_LIBRARY == null:
		return null
	return SONG_LIBRARY.keys()

func set_song():
	pass

func start_song( song_name : String ) -> void:
	current_song = song_name
	current_segment = SONG_LIBRARY[current_song].starting_segment
	bar_length = (60.0 / float(SONG_LIBRARY[current_song].bpm)) * (4.0/float(SONG_LIBRARY[current_song].timesig2)) * float(SONG_LIBRARY[current_song].timesig1)
	_init_song()
	_init_midi()
	is_playing = true
