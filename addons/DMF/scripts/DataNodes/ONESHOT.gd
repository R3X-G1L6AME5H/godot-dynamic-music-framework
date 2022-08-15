extends DMFLibraryClasses
class_name DMFOneshot

"""
	Dynamic Music Framework Transition Node
		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)

	A (child) data node used by the DMF Song. This node adds a bit
	of randomness to the entire piece. It sets a probability of the track playing.
	This can embelish long repeating loops.
"""

const lib_node_type = 2  # Dirty and cheap way of determinig if a Node is a part of this plugin.


## Path to the audio track (.wav, .ogg, or .mp3)
export (String, FILE, "*.wav,*.ogg") var oneshot_sound
## The bar at which the audio track is ment to start playing
## 		(BPM is set in DMFSong)
export (int) var start_bar = 0
## The probability of this audio track playing
export (float, 0.0, 1.0) var trigger_chance = 1.0
