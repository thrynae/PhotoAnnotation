This function opens a GUI showing a photo and user-added comments. These comments extracted from the comment field, which is possible for jpeg, tiff and png. All EXIF data is preserved using a tool that is downloaded on first run (exiftool).

This function was written to be packaged in a one-click solution using the portable version of Octave. http://tiny.cc/PhotoAnnotation should point to a folder containing setup files for each version that downloads Octave 4.2.1 and has an exe wrapper to start this function as an application. File association might work on some systems. In case of overzealous anti-virus programs block the setup file, a manual setup is also available on that link for easy sharing with non-tech savvy people.  
An update mechanism (which will backup and replace the m-file) was implemented in version 1.2. This will probably break with the move to GitHub. If and when it comes, version 2.0 will include a new update mechanism.  
This function was tested on R2017b, R2012b and Octave 4.2.1. For R2013a and earlier, a replacement for the strsplit function is needed, but otherwise it works. Non-Windows systems will need some adjustments in the system calls (a Mac version of exiftool is available, as well as a perl version).

Licence: CC by-nc-sa 4.0