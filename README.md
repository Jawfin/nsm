This is a solution I found for the mouse sticking when having monitors arranged vertically instead of horizontally and forked. I ported it to C# WPF, split the range to be rangey and rangex to handle different monitor border sizes and added commandline arguments e.g. NonStickMouse.exe --rangex=2 --rangey=2 --hoplimit=30

NSM Debug can be used to help you figure out the correct values for the arguments
http://www.jawfin.net/download/NSMDebug.zip
http://www.jawfin.net/?page_id=143


# nsm
Non Stick Mouse. A simple app which allows the mouse to hop over the corners of multiple monitors in Windows 10.
See http://jawfin.net/nsm for more details.
