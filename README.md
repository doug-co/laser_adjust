# LaserAdjust

This program is used to update a CNC's compensation table, with adjustment data from a
laser level. It outputs new compensation tables (or optionally will overwrite the original).

A CNC machine can have imperfections in the level of its axis which come from manufacturing
defects, affects from installation or the surface it is installed upon.  A compensation table
provides adjustments which the machine can use to compensate for these imperfections. This is
done by adding adjustments or interpolations of adjustments to the position of the cutting
head based on the position of the head along a particular axis.  There would normally be a
compensation table for each axis.  A laser level is used to to find the imperfections in the
positions of the cutting head, which is then generated as a file.  This program takes the
adjustment file from the laser lever, and the compensation table from the CNC machine and
combines them to create an updated compensation table.

Laser adjust will automatically discover files based on the following patterns

  `{axis} <description>.pos`   - describes a laser adjustment file
    *Valid Examples*:
       X.pos, Y Axis.pos, A Axis Forward.pos
    *Description*:
       This file contains adjustment values used to adjust the compensation values in the
       compensation files.

  `AL{axis}`  - describes an 8055 type compensation file
    *Valid Examples*:
      ALX, ALY, ALA, ALB

  `{axis}.mp`  - describes an 8065 type compensation file
    *Valid Examples*:
      X.mp, Y.mp, P.mp, Q.mp

Multiple axis compensation files will be paired with adjustment files based on their axis
names.  The software will process all files where a matching pair is found.

## Installation
The following assumes an elixir environment is setup on your system.

  1. Download the source or clone this repository

  2. cd to .../laser_adjust

  3. run: ```mix escript.build```

    This will build the script which can be run on any Erlang environment.
    
## Usage

laser_adjust is a commandline program, options are described below.



```
usage: laser_adjust path [--quiet|-q] [--force|-f]
                         [--axis|-a {axis-name A-Z}] [--type|-t {8055|8065}]
```
  path is a directory which specifies the location to find the compensation and
  adjustment files, as well as where updated files will be created.  If no path is
  provided, the current directory is used.

### Options

  `--quite|-q`  -- turn off log messages

  `--force|-f`  -- force overwrite of original compensation table files with the updated file.

  `--axis|-a`   -- process only axis listed, multiple --axis or -a options can be supplied
                   to process only selected axis.

  `--type|-t`   -- only process files for the specified type.

### Examples

  Find all axis compensation and adjustment file pairs and produce a new compensation file
  for each pair found.

  `laser_adjust`

  Only valid X and Y axis pairs are processed to produce a new compensation for.  
  
  `laser_adjust --axis X --axis Y`

  Only valid X and Y axis pairs are processed if they are of the valid type.  So in the
  following case it will process ALX and ALY files, but skip the axis if the compensation
  file is X.mp or Y.mp.

  `laser_adjust --axis X --axis Y --type 8055
  