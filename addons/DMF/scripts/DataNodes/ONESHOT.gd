extends DMFLibraryClasses
class_name DMFOneshot

const lib_node_type = 2

export (String, FILE, "*.wav,*.ogg") var oneshot_sound
export (int) var start_bar = 0
export (float, 0.0, 1.0) var trigger_chance = 1.0
