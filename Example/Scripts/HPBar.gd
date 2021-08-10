extends ProgressBar


func _ready():
# warning-ignore:return_value_discarded
	Blackboard.connect("blackboard_value_set", self, "_track_health")

func _track_health( key ):
	if key == "HP":
		if Blackboard.has("HP_MAX"):
			self.value = Blackboard.get("HP") / Blackboard.get("HP_MAX")
			#print(value)
