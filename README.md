# Godot Dynamic Music Framework
## What is this?
It is a Godot plugin for dynamic music, with an added bonus of being able to read midi files.

## Usage
This plugin is composed of 3 parts in total. The `MusicController`, the `Blackboard`, and the PlaylistGenerator. The `MusicController` and the `Blackboard` are singletons, meaning that they are available from anywhere within the project. 

The `Blackboard` is ment to store all the states going on in-game and make that data accessible by every script in the project. 

The `MusicController` is the thing that plays all the sounds. It will read the `Blackboard`, and adapt how, and what it plays all according to its setup in the `Library.gd` file. `Library.gd` is generated by the PlaylistGenerator component. 

### PlaylistGenerator
PlaylistGenerator is made up of many smaller nodes which simplify the organization of all the files, and settings. At the top of all the nodes is the `DMFPlaylistGenerator` node aka. the Generator. If you select it, you will see that this node has a singular property: toggle. When pressed, it will generate `res://Library.gd` file. Second is the `DMFSong` node. This node defines all the songs available to the `MusicController`. Here you will define the song's BPM and its Time Signature. 

Lastly, there come the nodes you'll spend most of your time with. First lets talk about the `DMFTrack` node. It's job is to play a sound file. 

```
Generator
\--Song
   \-- Tracks
   \-- Segments
   \-- Oneshots
   \-- Watchdogs
   \-- Midi's
   
```

### Blackboard
### MusicController
