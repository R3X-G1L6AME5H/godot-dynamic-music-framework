extends Object
const library = {
	"SONG": {
		"bpm": 140,
		"timesig1": 4,
		"timesig2": 4,
		"starting_segment": "SEG_Chill",
		"tracks": {
			"TR_Violins 1": {
				"path": "res://Example/Assets/TRACK_!/1_Violin 1.ogg",
				"start": 0,
				"end": 16
			},
			"TR_Violins 2": {
				"path": "res://Example/Assets/TRACK_!/2_Violin 2.ogg",
				"start": 0,
				"end": 16
			},
			"TR_Violas": {
				"path": "res://Example/Assets/TRACK_!/3_Viola.ogg",
				"start": 0,
				"end": 16
			},
			"TR_Bass": {
				"path": "res://Example/Assets/TRACK_!/4_Bass.ogg",
				"start": 0,
				"end": 16
			}
		},
		"midis": {
			"MT_HIGH_HP_MIDI": {
				"midi": "res://Example/Assets/MIDIS/HighHP.mid",
				"start": 0,
				"end": 16,
				"single_trigger": false,
				"pitch": false,
				"floor": 0.32,
				"ceil": 1,
				"current": "HP",
				"max": "HP_MAX"
			},
			"MT_LOW_HP_MIDI": {
				"midi": "res://Example/Assets/MIDIS/LowHP.mid",
				"start": 0,
				"end": 16,
				"single_trigger": false,
				"pitch": false,
				"floor": 0,
				"ceil": 0.32,
				"current": "HP",
				"max": "HP_MAX"
			},
			"MT_PITCH": {
				"midi": "res://Example/Assets/MIDIS/Pitch.mid",
				"start": 0,
				"end": 16,
				"single_trigger": false,
				"pitch": true,
				"bus": "PitchShifter",
				"sfx": 0,
				"floor": 0,
				"ceil": 1
			}
		},
		"segments": {
			"SEG_Chill": {
				"start": 0,
				"end": 8,
				"transitions": [
					{
						"current": "INTENSITY",
						"max": "INTENSITY_MAX",
						"ceil": 1,
						"floor": 0.5,
						"target": "SEG_Intense"
					}
				]
			},
			"SEG_Intense": {
				"start": 8,
				"end": 16,
				"transitions": [
					{
						"current": "INTENSITY",
						"max": "INTENSITY_MAX",
						"ceil": 0.5,
						"floor": 0,
						"target": "SEG_Chill"
					}
				]
			}
		},
		"watchdogs": [
			{
				"track": "TR_Bass",
				"current": "HP",
				"max": "HP_MAX",
				"target": "VOL",
				"graph": {
					"pos": [
						[
							0.20339,
							0
						],
						[
							0.440678,
							-33
						]
					],
					"tg": [
						[
							0,
							-1.68573
						],
						[
							-327.450012,
							0
						]
					],
					"tgm": [
						0,
						0
					]
				}
			},
			{
				"track": "TR_Violas",
				"current": "HP",
				"max": "HP_MAX",
				"target": "VOL",
				"graph": {
					"pos": [
						[
							0.292373,
							0
						],
						[
							0.597458,
							-33
						]
					],
					"tg": [
						[
							0,
							-1.68573
						],
						[
							-296.332001,
							0
						]
					],
					"tgm": [
						0,
						0
					]
				}
			},
			{
				"track": "TR_Violins 2",
				"current": "HP",
				"max": "HP_MAX",
				"target": "VOL",
				"graph": {
					"pos": [
						[
							0.351695,
							-33
						],
						[
							0.737288,
							0
						]
					],
					"tg": [
						[
							-327.450012,
							230.100006
						],
						[
							0,
							-1.68573
						]
					],
					"tgm": [
						0,
						0
					]
				}
			},
			{
				"track": "TR_Violins 1",
				"current": "HP",
				"max": "HP_MAX",
				"target": "VOL",
				"graph": {
					"pos": [
						[
							0.220339,
							-10.2
						],
						[
							0.504237,
							0
						]
					],
					"tg": [
						[
							-327.450012,
							-3.21818
						],
						[
							0,
							-1.68573
						]
					],
					"tgm": [
						0,
						0
					]
				}
			}
		],
		"oneshots": [
			{
				"path": "res://Example/Assets/TRACK_!/1_FLUTE_OS1.wav",
				"start": 1,
				"chance": 0.15
			},
			{
				"path": "res://Example/Assets/TRACK_!/2_FLUTE_OS2.wav",
				"start": 3,
				"chance": 0.15
			},
			{
				"path": "res://Example/Assets/TRACK_!/3_FLUTE_OS3.wav",
				"start": 4,
				"chance": 0.15
			},
			{
				"path": "res://Example/Assets/TRACK_!/4_FLUTE_OS4.wav",
				"start": 6,
				"chance": 0.15
			},
			{
				"path": "res://Example/Assets/TRACK_!/5_BASSOON_OS1.wav",
				"start": 0,
				"chance": 0.15
			},
			{
				"path": "res://Example/Assets/TRACK_!/6_BASSOON_OS2.wav",
				"start": 2,
				"chance": 0.15
			},
			{
				"path": "res://Example/Assets/TRACK_!/7_BASSOON_OS3.wav",
				"start": 4,
				"chance": 0.15
			},
			{
				"path": "res://Example/Assets/TRACK_!/8_BASSOON_OS4.wav",
				"start": 6,
				"chance": 0.15
			}
		]
	}
}
