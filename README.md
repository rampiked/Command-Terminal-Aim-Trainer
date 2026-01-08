Matt Sagat - Personal Project, Command Terminal-Based Aim Trainer

FOR THE BEST UNDERSTANDING OF THIS NICHE PROJECCT, I STRONGLY RECCOMEND WATCHING THESE YOUTUBE VIDEOS BEFORE DIGGING THROUGH THIS REPOSITORY

Project Demonstration: https://www.youtube.com/watch?v=H6U8mhcOyvs

Included Github File Overview: https://www.youtube.com/watch?v=wsWg5wNnPVQ

This tool allows those in the Roblox RCL community to easily get aiming practice against bots in customizable environments. 

Full list of current features:
/set wall dist [num] --Sets the wall to be num studs from the center of the map (user spawn point).
/set wall color [color] --Changes the wall color to the user specified color.
/set cursor [cursor id] --Changes the user's cursor using a Roblox image asset ID.
/set bot quantity [num] --Updates the quantity of bots within the arena.
/acc --Prints the user's current accuracy into the terminal.
/resetacc --Resets the user's accuracy.

I personally wrote everything other than the code that positions the held gun in the user character's arms. I didn't even upload that file but it is not important.

Other considerations:
Bots always spawn within the current wall distance set.
There are upper and lower bounds to valid wall distances, with errors if you exceed the bounds.

Future ideas:
Allow loading of maps via terminal.
Create different bot dodging modes.
