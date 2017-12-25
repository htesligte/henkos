# henkos
Hobby (toy) os based on http://www.independent-software.com/writing-your-own-toy-operating-system/

# Script to run:
I'm using the following code to build an image. This requires both wine and imagefs.exe from the above tutorial on a linux machine. 
The resulting `test.img` file can be used with bochs or qemu to boot. 
````
#!/bin/bash
nasm boot.nasm -f bin -o boot.bin
nasm 2ndstage.nasm -f bin -o 2ndstage.bin
rm test.img
wine imagefs.exe c test.img 720
wine imagefs.exe b test.img boot.bin
wine imagefs.exe a test.img 2ndstage.bin
````

# Notes
* The image has an invalid fat12 bootsector at the moment because I didn't really understand how some data was loaded. I will fix this once I get to it.
* Currently I use imagefs.exe from that tutorial to build a floppy image, but I'm sure there are plenty enough linux tools that can do the same job.
