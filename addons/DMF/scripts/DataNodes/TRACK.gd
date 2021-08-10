extends DMFLibraryClasses
class_name DMFTrack

const lib_node_type = 0

export (String, FILE, "*.ogg") var music_track
export (int) var start_bar
export (int) var end_bar
export (bool) var low_pass_filter
export (bool) var notch_filter
export (bool) var high_pass_filter
export (bool) var panner
#export (bool) var pitch_shift
