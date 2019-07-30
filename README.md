# BOLT-LMM for Windows
Windows implementation of BOLT-LMM by Po-Ru Loh using MinGW

Compiled with MinGW on a i7-8750H

Libraries used: OpenBLAS 0.3.7.dev.a 2019-07-24 (Compiled for Sandybridge), nlopt 2.6.1, boost 1.70.0

BOLT-LMM is a fantastic tool for Genome Wide Association Studies (GWAS) written by Po-Ru Loh. The original version is [available here](https://data.broadinstitute.org/alkesgroup/BOLT-LMM/). Since it is originally written for Linux I had to modify some part of the code to make it compile with MinGW and run it on Windows.

# Notes
If you run into errors, try installing MinGW and make sure the MinGW\bin folder is defined in your path.

BOLT-LMM was created to recognise colon as a sequence marquer, like in `file_{1:22}.bed`. Unfortunately that prevents us to use absolute paths in windows where the Drive letter is followed by a colon, like in `C:\Path`. In a recent release, the sequence marquer has been replaced by `@` as in `file_{1@22}.bed`.


Author's website: http://remidaviet.com
