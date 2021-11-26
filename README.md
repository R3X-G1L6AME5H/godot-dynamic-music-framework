# Godot Dynamic Music Framework
## What is this?
It is a Godot plugin for dynamic music. It was designed to add dynamics to the game soundtrack. If you're looking for a tool that can mix and blend between track depending on the ingame variables, I got you. If you're looking for a tool that can play musical motifs randomly in the track, I got you. If you need a way to sync your game with the music in the background without headaches, I got you. 

What does the workflow look like? Open your favourite DAW. Make your music. Export your tracks and midi's to your project's asset directory. Use the Playlist Generator to quickly and intuitively organize your music in a way the plugin will understand. Organize your sound buses. Wire up your scripts to the `MusicController`'s signals. And bada-bing bada-boom, all is good.

## Usage
There is quite a bit to go through so the usage will be explained through an example; a real-life use case for this plugin. I will also try to fit as many images as posible for better viewing experience.

## Act I - Before I forget
Before we start, we need to figure out what we want. For this example, I wish to make a simple bullet-hell game in which attacks syncronize with music. 

So what do we need for this. What game states exist that the music will highlight. Lets start simple, low HP. Something happens to the music when player gets hurt. This implies that there is certain music playing when player is ok. Further more, since I am a lazy dev, lets make it so that when the player survives for long enough the music shifts to something more upbeat. Like a stage two of a boss fight.

So that makes four states. Stage I, Stage II, Stage I low HP, and Stage II low HP. In this composition, lets have a string section and a brass section. The string section will be fast, while the brass section will be slow and grand. Idea is to make the music (and consequently the attacks) fast when Player's HP is high, and slow when Player's HP is low. And maybe we'll add a piano for some random fills to keep the music interesting.


![Plan Diagram](https://raw.githubusercontent.com/R3X-G1L6AME5H/godot-dynamic-music-framework/master/Example/Images/PlanDiagram.png)


## Act II - Beeps and Boops
Now its time to actually write the music. Open up your favourite DAW, and/or get ready to record. I will use LMMS. There is a couple things to keep track of for future refference; BPM, Time Signature, and Bar numbers. 
![Whacha Lookin For](https://raw.githubusercontent.com/R3X-G1L6AME5H/godot-dynamic-music-framework/master/Example/Images/FOR_THE_UNAFFILIATED.png)
BPM and time signature will give the plugin the lenght of a bar. This is important because the plugin figures out what to play and when to play it depending on which bar it's in.

I have gone ahead and made a little composition for the demo. The composition looks like this. So what is going on here. As planned, we have three instrumental sections: the **Strings**(Violins, Violas, Cellos, and Contrabass'), the **Brass**(Trumpets, Horns, and Trombones), and the **Piano**. The strings are playing in a fast rhytmic staccato, while the brass plays long, majestic, legato. Finally we have the piano to add a bit of randomness and interest to these 16 bars. Finally, if you look closely, there is an Events instrument at the bottom; this will become important later.

So, what did I take into consideration when making this track. 
#### Horizontal Mixing
Hoizontal mixing is very simple. It assumes that your music is divided into sections. You just have to make sure that whatever comes *after* your section, fits well with the *end* of your section. In the example, the first eight bars work well regardless of if they [loop to the begining](), move on to the [next eight bars](). 

When working on your music, you aim to make the jumps between sections as unnoticable as posible. This will mostly depend on the melody, rhythm, and chord progression. The lenght of your section will play the part as well: a stutter every 4 bars is far more noticable than the stutter that occurs every 16 bars. This will come at the cost of music's adaptability, since it will take it a while longer to get to the end, where the jump occurs, but it wouldn't matter much for more environmental music. 

Another thing that will help mask the jump is reverb. **DO NOT APPLY IT IN YOUR DAW!** Its better to let Godot handle the reverb. This is because the plugin simply plays a file. When a jump occurs it just moves to another place in that file. It ignores everything after it, including the tail of the reverb. Then the stututer becomes even more obvious: not only does the music change, but the reverb dissapears as well. Letting Godot handle the reverb fixes this issue.

#### Vertical Mixing
Vertical mixing doesn't jump between tracks like horizontal mixing, but rather, it blends between them. The tracks play at the same time, but at different volumes. Imagine you were playing to recordings on two phones. One phone plays the piano part, and the other plays the violin part for the same song. If both recordings are in sync, you can mix between them by turning the volume of the phone up or down. First only the piano plays. Then you gently turn up the violin part, and now they mix together. This is vertical mixing.

So what do you need to keep track? Firstly, you must divide the sounds playing at the same time into sections(again). We already did this for this example, remember: Brass, Strings, and Piano. Strings on high HP, and brass on low HP. Next, you must make them sound good. Both [together](), and [apart]().

#### Embelishments
To make your music more dynamic, you can add some randomness to it. Little musical motifs which sometimes play... and sometimes don't. Even a looping 4 chord progression can sound godly if there is a good solo floating above it. Just add some simple motif's, embelishments, or odd notes. Do try to make them sound good with whatever is in the background, but also plan for their uncertain nature.

#### Pitch Correction
This has nothing to do with the DAW itself. Think back to games like Abzu, or Journey, where each sound effect plays like an instrument, adding a bit of harmonic, and melodic complexity. Now, you could chose to make your game's sound effects meldical when making them, but maybe you wish to make them melodical retroactivly. In comes pitch correction. To be precise, it is just a midi file. And in this midi file, there is **only a melody** i.e. **only one note** is being pressed at a time. When the plugin reads this file, it will attempt to pitch shift every sound connected to a certain audio bus in Godot.

#### Events
Up till this point we have only looked at ways to make the music addapt to the gameplay, but now we shall take a look at a way for the music to influence the gameplay.



* The making of the soundtrack(what to keep in mind)
* the exporting

## Act III - Organizing the goods
* the nodes explained and visualized

![Music Structure](https://raw.githubusercontent.com/R3X-G1L6AME5H/godot-dynamic-music-framework/master/Example/Images/DMF_ABSTRACT.png)

## Act IV - The Conductor
* how to set up your scene(bus layout)
* wiring up the signals


This plugin is composed of 3 parts in total. The `MusicController`, the `Blackboard`, and the PlaylistGenerator. The `MusicController` and the `Blackboard` are singletons, meaning that they are available from anywhere within the project. 

The `Blackboard` is ment to store all the states going on in-game and make that data accessible by every script in the project. 

The `MusicController` is the thing that plays all the sounds. It will read the `Blackboard`, and adapt how, and what it plays all according to its setup in the `Library.tres` file. `Library.tres` is generated by the PlaylistGenerator component. 



### PlaylistGenerator
PlaylistGenerator is made up of many smaller nodes which simplify the organization of all the files, and settings. At the top of all the nodes is the `DMFPlaylistGenerator` node aka. the Generator. If you select it, you will see that this node has a singular property: toggle. When pressed, it will generate `res://Library.gd` file. Second is the `DMFSong` node. This node defines all the songs available to the `MusicController`. Here you will define the song's BPM and its Time Signature. 

#### Tracks
Lastly, there come the nodes you'll spend most of your time with. First lets talk about the `DMFTrack` node. It's job is to play a sound file; simple as. 

#### Segments
Next up is the `DMFSegment` node. One thing you should familiarize yourself with is the concept of bars. Bars are a certain time frame of music. It is calculated using the BPM, and the Time Signature specified in `DMFSong` node. Otherwise, it is very easy to use. Specify FROM which TO which bar a segment will span. )Insert example( Later on, you will be able to switch from one segment to the next, making your game music more dynamic. 

#### Oneshots
Speaking of dynamic, I introduce you to `DMFOneshot` node. Oneshots have a certain chance of playing any time the song loops back to them. This can add spice to your music. What I call "Oneshots" is what Mick Gordon used on his Doom OST. Making a few riffs which would play randomly throught the song. 

#### Watchdogs
`DMFWatchdog` is where things get crazy. The jist of is: you select a track, one of ITS properties, one of the WORLD's properties, WORLD property's max value, and a graph of how it should respond. Imagine it this way: The game starts and you have this piano track playing. The player gets hit, and the health drops bellow 50%. Along with it, the piano gets quieter, and a violin fades in. How? Watchdogs. You start with two tracks: the piano and the violin. Then you make two watchdogs. You make one watchdog target the piano track, and the other one target the violin track. You tell them their `Current Property` is "PlayerHP", and that the `Property Max` is "PlayerHPMax"(both of which must be available in the Blackboard), and to `Change Property` Volume. Lastly, you create the new curves for the `Change Graph`. One whose value is high above 50%, and one whose value is high BELOW 50%. That is how you get the example above. 

#### Midi's
And then there is the `DMFMidi` node. This node is intended to syncronize the music and the bahaviour in game. Up until this point, the music reacted to the player, but here on out the player reacts to the music. Any game which has a rhythm element to it can benefit from this node. The idea is to use your favourite DAW to create a midi file in line with the music being played, each note coresponding to a certain behaviour. Say, in a guitar hero like game, you could map the RED button to note C2, BLUE button to note D2, and the YELLOW button to note E2. The `MusicController` will process this midi file alongside the track file, and emit signals when a note is on, and when its off. Since the `MusicController` is a singleton, you can connect any object to it by simply writing `MusicController.connect("note_on", self, "_on_Node_note_on")`, and `MusicController.connect("note_off", self, "_on_Node_note_off")`(This assumes that you know how connecting signals works). There is no end to what you can do with this functionality.


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

## TO DO
These are some of the things that will probably interupt my game development.
- Get rid of the `Library.gd` and replace it with `Library.tres`. Far more efficient.
- Add transitions. There is currently no way to hop between segments, or songs.
- Give Watchdogs more properties they can influence e.g. Filters, Panning, Overdrive, Flanger, etc.
