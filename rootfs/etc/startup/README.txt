Any file with extension .sh in this directory will be sourced during the startup of the container.
The following variables are available:
* ```$USER``` is the user name of the user connected to the session
* ```$HOME``` is the home directory of that user
* ```$RESOLUTION```, if defined, is the resolution of the display, in the form ```<width>x<height>``` in pixels.
