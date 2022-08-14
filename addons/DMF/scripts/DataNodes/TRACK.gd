extends DMFLibraryClasses
class_name DMFTrack

"""
	Dynamic Music Framework Track Node
		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)

	A (child) data node used by the DMF Playlist Generator. The refference to Audio
	Tracks. This node is what organizes the played audio.
"""

const lib_node_type = 0 # Dirty and cheap way of determinig if a Node is a part of this plugin.

## Path to the audio track (.wav, .ogg, or .mp3)
export (String, FILE, "*.ogg") var music_track
## The bar at which the audio track is ment to start playing
## 		(BPM is set in DMFSong)
export (int) var  start_bar
## The bar at which the audio track is ment to stop playing
export (int) var  end_bar


## In the future, it will be possible to apply these effect to the track at runtime
#export (bool) var low_pass_filter
#export (bool) var notch_filter
#export (bool) var high_pass_filter
#export (bool) var panner
#export (bool) var pitch_shift
