# Marmoview
MarmoV5 is the current working version of Marmoview, which runs the stimulus / behavioral protocols from [Marmolab](https://marmolab.bcs.rochester.edu/people.html) at the University of Rochester.

# Setup
This codebase is not user friendly. If you are interested in working with it, contact [Jake Yates](yates@umd.edu) by email. In the future, he might write a wiki page on how to use it, but for now, email to set up a meeting. Before you do that though,
follow these steps to make sure it is installed on you machine (You can run it on your laptop if you jsut want to test it).

### Steps

1. Fork the repository. Clone that fork to you own your own machine
2. Open matlab, change to the MarmoV5 directory and add all paths

``` 
addpath(genpath(pwd))
```
3. Edit the `MarmoViewRigSettings.m` file and switch the RigName to 'laptop', or set up your own rig. Use the existing rigs as models for this.
4. Open the Marmoview GUI from the command window
```
MarmoV5
```
This will open the Marmoview GUI. Enter the subject name and hit enter. Then use the `SettingsFile` tab and hit `Browse` to load a protocol. Pick `Forage11_DriftingGratings` to get started.

Make sure this runs. Then contact Jake.

### Debugging tricks
If MarmoV5 crashes, close the screen with `sca` and close the GUI with `close all force`. This will get you back to the starting point.


### Aknowledgements
Marmoview has been developed by several people over the years and is based off the synchronization schema developed for [PLDAPS](https://www.frontiersin.org/articles/10.3389/fninf.2012.00001/full)
Jacob Yates, Sean Cloherty, Sam Nummela, Jude Mitchell
