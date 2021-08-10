extends Node

### CORE NOTE IS C

const twelfth : float = 1.0/12.0

const bpm : float = 140.0

#enum NOTES {C, CS, D, DS, E, F, FS, G, GS, A, AS, B}
#export (NOTES) var sound_note = NOTES.C
var position : float = 0

var data
var notes_on = {}

class GodotMIDIPlayerTrackStatus:
	var events:Array = []
	var event_pointer:int = 0

onready var track_status : GodotMIDIPlayerTrackStatus = GodotMIDIPlayerTrackStatus.new( )
 
signal note_on( note )
signal note_off( note )


func _init_track( ) -> void:
	var track_status_events:Array = []

	if len( self.data.tracks ) == 1:
		track_status_events = self.data.tracks[0].events
	else:
		# Mix multiple tracks to single track
		var tracks:Array = []
		var track_id:int = 0
		for track in self.data.tracks:
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
				
				var e:SMF.MIDIEventChunk = track.events[p]
				var e_time:int = e.time
				if e_time == time:
					track_status_events.append( e )
					track.pointer += 1
					next_time = e_time
				elif e_time < next_time:
					next_time = e_time
			time = next_time

	#self.last_position = track_status_events[len(track_status_events)-1].time
	self.track_status.events = track_status_events
	self.track_status.event_pointer = 0

func _ready():
	var smf = SMF.new()
	data = smf.read_file("res://test.mid")
	track_status.event_pointer = 0
	_init_track()
	$AudioStreamPlayer.play()
	$Master.play()


func _process(delta):
	var playback = $AudioStreamPlayer.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	## printt( ($Master.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() ) - playback )
	position = ( playback ) * ((data.timebase * bpm) / 60.0)
	#printt(playback,position)
	#time = playback
	
	#position += float( data.timebase ) * delta * (bpm/60.0) # * self.play_speed
	var length : int = len( track_status.events )
	
	## IN CASE THE TRACK OVERFLOWS
	if length <= track_status.event_pointer:
		return
	#	if self.loop:
	#		var diff:float = self.position - track.events[len( track.events ) - 1].time
	#		self.seek( self.loop_start )
	#		self.emit_signal( "looped" )
	#		self.position += diff
	#	else:
	#		self.playing = false
	#		self.emit_signal( "finished" )
	#	return 0
	
	var execute_event_count : int = 0
	var current_position : int = int( ceil( position ) )
	
	while track_status.event_pointer < length:
		var event_chunk:SMF.MIDIEventChunk = track_status.events[track_status.event_pointer]
		if current_position <= event_chunk.time:
			break
		track_status.event_pointer += 1
		execute_event_count += 1
	
		var event : SMF.MIDIEvent = event_chunk.event
		match event.type:
			SMF.MIDIEventType.note_off:
				var event_note_off : int = ( event as SMF.MIDIEventNoteOff ).note
				notes_on.erase(event_note_off)
				emit_signal("note_off", event_note_off)
			
			SMF.MIDIEventType.note_on:
				var event_note_on : SMF.MIDIEventNoteOn = event as SMF.MIDIEventNoteOn
				notes_on[event_note_on.note] = event_note_on.velocity
				emit_signal("note_on", event_note_on)

#func get_note_length( note : int, start_position : float) -> float:
#	var new_position:int = int( floor( start_position ) )
#	var length:int = len( track_status.events )
#	var pointer:int = 0
#	var timer_start : float = 0
#	var is_timing = false
#	
#	while pointer < length:
#		var event_chunk:SMF.MIDIEventChunk = track_status.events[pointer]
#		### FIND THE BEGINING
#		if new_position <= event_chunk.time and not is_timing:
#			timer_start = event_chunk.time
#			is_timing = true
#		
#		### FIND THE END
#		if is_timing:
#			if event_chunk.event.type == SMF.MIDIEventType.note_off:
#				if note == ( event_chunk.event as SMF.MIDIEventNoteOff ).note:
#					prints(timer_start, event_chunk.time)
#					return (event_chunk.time - timer_start) #/ ((data.timebase * bpm) / 60.0)
#		
#		pointer += 1
#	return 0.0

func seek( to_time : float ):
	### CLEAR THE SLATE
	for note in notes_on.keys():
		emit_signal("note_off", note)
	notes_on.clear()
	
	### SYNC LAST_TIME AND PLAYBACK
	$AudioStreamPlayer.seek(to_time)
	
	self.position = to_time * ((data.timebase * bpm) / 60.0)
	var pointer:int = 0
	var new_position:int = int( floor( position ) )
	var length:int = len( track_status.events )
	for event_chunk in self.track_status.events:
		if new_position <= event_chunk.time:
			break
		pointer += 1
	track_status.event_pointer = pointer


