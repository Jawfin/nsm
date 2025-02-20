# Non Stick Mouse
A simple app which allows the mouse to hop over the corners of multiple monitors in Windows 10 & 11.
See https://jawfin.net/nsm for more details.

The commandline arguments currently are: -

lag [n] ; where n is the milliseconds between checks of mouse position.  Default is 500 (half a second).

corners ; if this parameter is found then it will only attempt to hop the mouse in the corners only.  Otherwise it will do it along the whole edge, which is needed for moving windows between screens.


These parameters can also be built into the filename itself.  So if the app is renamed to `nsm corners.exe` it'll activate the corners flag, ditto for lag and an integer after it.

NSM Debug can be used to help you figure out the correct values for the arguments
https://jawfin.net/download/NSMDebug.zip
https://www.jawfin.net/nsm/comment-page-1/#comment-14930


# WPF/NonStickMouse - by longlostbro
This is a solution I found for the mouse sticking when having monitors arranged vertically instead of horizontally and forked. I ported it to C# WPF, split the range to be rangey and rangex to handle different monitor border sizes and added commandline arguments e.g. NonStickMouse.exe --rangex=2 --rangey=2 --hoplimit=30
