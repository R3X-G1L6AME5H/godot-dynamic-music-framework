extends DMFLibraryClasses
class_name DMFSegment

"""
	Dynamic Music Framework Track Node
		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)

	A (child) data node used by the DMF Song. The purpuse of Segments
	is to determine the horizontal sections of a track. These are later used by
	transitions to move between different areas in the track.

"""

const lib_node_type = 1  # Dirty and cheap way of determinig if a Node is a part of this plugin.

## The bar at which the segment starts
## 		(BPM is set in DMFSong)
export (int) var starting_bar
## The bar at which the segment ends
export (int) var ending_bar
