extends Node

"""
	Dynamic Music Framework - Music Controller
		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)

	THE MOST IMPORTANT SCRIPT!!! This singleton is what manages all the data, sounds,
	and events which allow for dynamic music.
"""




"""
	LOADING THE PLAYLIST
"""
export (String, FILE, "*.tres") var path_to_song_library = "res://Library.tres"
var SONG_LIBRARY : Dictionary

func _ready():
	### Get the playlist
	var file = File.new()
	file.open(path_to_song_library, File.READ)
	SONG_LIBRARY = file.get_var()
	file.close()



"""
	POSITION/TIME TRACKING
"""
## It turns out that the most accurate time tracking you can get
## is by playing an AudioPlayer node without sound, and reading
## it's pointer's current time/position
onready var clock = $SyncPlayer

## because an AudioPlayer node is used as the clock the only way to seek back is to reset the clock to 0
## clock offset exists to mark the starting point of playing
## 		i.e. current position = clock offset + clock time
var clock_offset : float = 0.0
var position : float = 0


"""
	AUDIO TRACK MANAGEMENT
"""
var current_song = ""

## how long (timewise) does a single bar last
var bar_length : float
## "current_*" reffers to the elements of the song that is currently selected
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




"""
	MIDI MANAGEMENT
		Adapted from Yui Kinomoto's (@arlez80) Midi Player plugin
"""

#### Allows for reading/writing MIDI Files. Curtesy of Yui Kinomoto (@arlez80)
const SMF = preload("res://addons/DMF/singletons/SMF.gd")
var midi_statuses = {}
var midi_enabled = false
var notes_on = {}  ## Contains all pressed notes, if any
signal note_on ( channel, note )  ## A signal emited when a note is pressed
signal note_off( channel, note )  ## A signal emited when a note is let go

class GodotMIDIPlayerTrackStatus:
	var playing       : bool  = false
	var type          : bool  = 0  
		### 0 - emit signals
		### 1 - pitch correction
	var notes_owned   : Dictionary = {}
	var events        : Array = []
	var event_pointer : int   = 0
	var timebase      : float = 0
	var start_time    : float
	var end_time      : float







"""
	GO THROUGH ALL TRACKS IN THIS SONG AND CREATE PLAYERS FOR IT.
"""
func _init_song() -> void:
	#### CREATE ALL PLAYERS
	for track in SONG_LIBRARY[current_song]["tracks"].keys():
		var player = Player.new()
		player.name = track
		player.start_time  = SONG_LIBRARY[current_song]["tracks"][track]["start"] * bar_length
		player.end_time    = SONG_LIBRARY[current_song]["tracks"][track]["end"] * bar_length
		player.stream      = load( SONG_LIBRARY[current_song]["tracks"][track]["path"] )
		
		## A bus is created for each audio player
		## 		This is so that you can add effects to each individual track, and be able to control them by script
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1, track)
		## Maestro is the send bus for all the players created by this plugin
		## 		This is so that the actual Master Bus is left untouched
		AudioServer.set_bus_send(AudioServer.get_bus_index(track), "Maestro")
		player.bus = track
		
		self.add_child(player)                 ### Remove with queue_free on current_players array
		current_players.append(player)
	
	#### CREATE ONESHOTS
	for oneshot in SONG_LIBRARY[current_song]["oneshots"]:
		var player = Player.new()
		player.name = "OS"
		player.start_time = oneshot.start * bar_length
		player.stream = load(oneshot.path)
		player.trigger_chance = oneshot.chance
		player.bus = "Oneshots"		 ## A bus for oneshots specifically
		current_oneshots.append(player)
		self.add_child(player)
	
	#### CONSTRUCT WATCHDOG CURVES
	for watchdog in SONG_LIBRARY[current_song].watchdogs:
		### TODO: Given that PlaylistGenerator saves to a .tres file, then the curve doesn't need to be reconstructed 
		###       since the object is stored as a variable
		
		## The curve is constructed anew
		var crv = Curve.new()
		for idx in range(watchdog.graph.pos.size()):
			crv.add_point(  Vector2(watchdog.graph.pos[idx][0], watchdog.graph.pos[idx][1]),
							watchdog.graph.tg[idx][0],
							watchdog.graph.tg[idx][1],
							watchdog.graph.tgm[idx] & 1,
							watchdog.graph.tgm[idx] & 2)
		crv.bake()
		watchdog_curves.append(crv)
	
	
	#### PICK THE CURRENT SEGMENT
	current_segment_start = SONG_LIBRARY[current_song]["segments"][current_segment]["start"] * bar_length
	current_segment_end   = SONG_LIBRARY[current_song]["segments"][current_segment]["end"] * bar_length
	
	#### TODO: consider moving the duty of starting the song elsewhere
	## Start all players which are supposed to play on start
	for player in current_players:
		if player.start_time == 0:
			player.playing = true
	
	clock.play()




"""
	GO THROUGH ALL MIDIS IN THIS SONG AND CREATE PLAYERS FOR THEM.
"""
func _init_midi( ) -> void:
	if SONG_LIBRARY[current_song]["midis"].empty():
		midi_enabled = false
		return
	
	### This has to do with how midi files are read and interpreted
	## Most of this is just coppied from Yui Kinomoto's (@arlez80) Midi Player plugin
	## so unless you wanna check that, just hope this doesn't break
	midi_enabled = true
	var smf = SMF.new()
	for track_key in SONG_LIBRARY[current_song]["midis"].keys():
		var midi_data = smf.read_file( SONG_LIBRARY[current_song]["midis"][track_key].midi )
		
		assert(midi_data != null, "Can't load " + SONG_LIBRARY[current_song]["midis"][track_key].midi + ".")
		
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





"""
	PROCESS EVERYTHING
"""
## TODO: consider changing with _physics_process
func _process(delta):
	if is_playing:
		### CHECK IF THE POSITION IS IN THE SEGMENT
		if current_segment_end - delta * 2.0 < position:
			## Jump to the begining of the segment if not
			for transition in SONG_LIBRARY[current_song].segments[current_segment].transitions:
				var tmp = float(Blackboard.get(transition.current)) / float(Blackboard.get(transition.max))
				if transition.floor <= tmp and tmp <= transition.ceil:
					current_segment       = transition.target
					current_segment_start = SONG_LIBRARY[current_song]["segments"][current_segment]["start"] * bar_length
					current_segment_end   = SONG_LIBRARY[current_song]["segments"][current_segment]["end"] * bar_length
				
			seek(current_segment_start)
		
		## KEEP TRACK OF TIME
		position = clock.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() + clock_offset
		
		_process_tracks() ## TURN PLAYERS ON/OFF
		
		_process_watchdogs() ## TRACK BLACKBOARD VALUES AND CHANGE TRACK PROPERTIES
		
		_process_oneshots(delta) ## ROLL A DICE TO SEE IF ANY ONESHOT SHOULD PLAY
		
		if midi_enabled: _process_midi() ## SEE IF ANY MIDI NOTES HAVE BEEN PRESSED




"""
	CONTROL WHEN TO TOGGLE PLAYERS.
"""
func _process_tracks() -> void:
	for player in current_players:
		### Turn on if [start_time < position]
		if player.start_time < position and not player.playing:
			player.seek(position - player.start_time)
			player.playing = true

		## Turn off if [end_time < position]
		elif player.end_time < position and player.playing:
			player.playing = false




"""
	CHECK HOW THE STATS THAT THE WATCHDOGS OBSERVE CHANGE,
	AND APPLY THE CHANGE TO A BUS PROPERTY.
"""
func _process_watchdogs() -> void:
	## CHECK ON WATCHDOGS
	for idx in range(SONG_LIBRARY[current_song].watchdogs.size()):
		## if properties being checked exist
		if Blackboard.has(SONG_LIBRARY[current_song].watchdogs[idx].current) and Blackboard.has(SONG_LIBRARY[current_song].watchdogs[idx].max):
			## map (current/max)[which is in range of 0-1] to the values in the watchdog curve
			var value = watchdog_curves[idx].interpolate_baked(
							clamp(  float(Blackboard.get(SONG_LIBRARY[current_song].watchdogs[idx].current)) / \
									float(Blackboard.get(SONG_LIBRARY[current_song].watchdogs[idx].max)) ,\
							0, \
							1) \
						)

			## APPLY THE CHANGE TO THE TARGET PROPERTY (volume, reverb, phaser, filter, etc)
			var bus_id = AudioServer.get_bus_index( SONG_LIBRARY[current_song].watchdogs[idx].track )
			match (SONG_LIBRARY[current_song].watchdogs[idx].target):
				"VOL":
					AudioServer.set_bus_volume_db(bus_id, value)

					## More on the way

"""
	"Roll the dice" TO SEE IF AN ONESHOT SHOULD BE PLAYED.
"""
func _process_oneshots( delta : float ) -> void:
	for oneshot in current_oneshots:
		if position > oneshot.start_time and position < oneshot.start_time + delta * 2:
			## Roll the dice
			if randf() <= oneshot.trigger_chance:
				oneshot.play()

"""
	EMIT SIGNALS WHEN NOTES ARE ON/OFF, GIVEN THAT THE TRIGGERS ARE SATISFIED.
		Note that this is practiaclly Copy/Pasted from Yui's work. I do NOT know HOW MIDI playing/reading/processing
		works, but I ensure you that it DOES
"""
func _process_midi() -> void:
	for stat_key in  midi_statuses.keys():

		### Checks if this MIDI should play or not
		if midi_statuses[stat_key].start_time < position and not midi_statuses[stat_key].playing:
			midi_statuses[stat_key].playing = true
			_midi_seek( position - midi_statuses[stat_key].start_time, stat_key )
		elif midi_statuses[stat_key].end_time < position and midi_statuses[stat_key].playing:
			midi_statuses[stat_key].playing = false
		
		if not midi_statuses[stat_key].playing:
			## Skip if not playing
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

		### This is where midi data is being looked up
		###### MIDI MAGIC
		while midi_statuses[stat_key].event_pointer < length:
			var event_chunk:SMF.MIDIEventChunk = midi_statuses[stat_key].events[midi_statuses[stat_key].event_pointer]
			if current_position <= event_chunk.time:
				break
			midi_statuses[stat_key].event_pointer += 1
			###### MAGIC OVER



			## CHECK IF TRIGGERS ARE SATISFIED
			## 		A trigger being a range of values that makes the midi play
			if SONG_LIBRARY[current_song]["midis"][stat_key]["single_trigger"]:
				if Blackboard.get(SONG_LIBRARY[current_song]["midis"][stat_key]["property"]) != SONG_LIBRARY[current_song]["midis"][stat_key]["value"]:
					### CLEAN ALL ACTIVE NOTES
					for note in midi_statuses[stat_key].notes_owned.keys():
						emit_signal("note_off", stat_key, note)
					midi_statuses[stat_key].notes_owned.clear()
					continue
			
			else:
				## No need to check if value is within range if the ENTIRE trigger range is selected
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
			
			
			### CHECK FOR NOTES (MIDI MAGIC)
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
			
			## HANDLE EVENT TRACK
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
	MOVE THE MARKER TO THE THE PLACE IN A SONG YOU WANT.
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
	A SPECIAL FUNCTION TO MOVE THE MIDI MARKER.
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
	Some control functions(sorely lacking)
"""
func get_song_list():
	if SONG_LIBRARY == null:
		return null
	return SONG_LIBRARY.keys()

func start_song( song_name : String ) -> void:
	current_song = song_name
	current_segment = SONG_LIBRARY[current_song].starting_segment
	bar_length = (60.0 / float(SONG_LIBRARY[current_song].bpm)) * (4.0/float(SONG_LIBRARY[current_song].timesig2)) * float(SONG_LIBRARY[current_song].timesig1)
	_init_song()
	_init_midi()
	is_playing = true
