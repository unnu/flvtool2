= FLVTool2 - Flash video manipulation

FLVTool2 is a manipulation tool for Macromedia Flash Video files (FLV).

== Overview

FLVTool2 calculates various meta data and inserts a onMetaData tag in the video. It cuts FLV files and adds cue Points (onCuePoint). A debug command shows the inside of a FLV file and the print command gives meta data information in XML or YAML format.

== Features

- batch processing
- directory recursion
- command chaining
- FLV file cutting
- onCuePoint tag insertation via XML file
- custom onMetaData key-value pairs
- meta data printout in XML or YAML
- simulation mode
- runs on Windows, Linux and Mac OSX
- ideal for serverside automatic meta data injection

== Installation

Most Linux OS's packet manager have FLVTool2 available.

```
apt-get flvtool2
```

Instllation via ruby gems:

```
gem install flvtool2
```

Manual installation:

Execute following commands in directory of README file:

```
ruby setup.rb config
ruby setup.rb setup
sudo ruby setup.rb install
```

Windows:

Download the flvtool2.exe file from here:

https://github.com/unnu/flvtool2/raw/master/flvtool2.exe

== Usage

```
$ flvtool2 
FLVTool2 1.0.6
Copyright (c) 2005-2007 Norman Timmler (Hamburg, Germany)
Get the latest version from https://github.com/unnu/flvtool2
This program is published under the BSD license.

Usage: flvtool2 [-ACDPUVaciklnoprstvx]... [-key:value]... in-path|stdin [out-path|stdout]

If out-path is omitted, in-path will be overwritten.
In-path can be a single file, or a directory. If in-path is a directory,
out-path has to be likewise, or can be omitted. Directory recursion
is controlled by the -r switch. You can use stdin and stdout keywords
as in- and out-path for piping or redirecting.

Chain commands like that: -UP (updates FLV file than prints out meta data)

Commands:
  -A            Adds tags from -t tags-file
  -C            Cuts file using -i inpoint and -o outpoint
  -D            Debugs file (writes a lot to stdout)
  -H            Helpscreen will be shown
  -P            Prints out meta data to stdout
  -U            Updates FLV with an onMetaTag event

Switches:
  -a            Collapse space between cutted regions
  -c            Compatibility mode calculates some onMetaTag values different
  -key:value    Key-value-pair for onMetaData tag (overwrites generated values)
  -i timestamp  Inpoint for cut command in miliseconds
  -k            Keyframe mode slides onCuePoint(navigation) tags added by the
                add command to nearest keyframe position
  -l            Logs FLV stream reading to stream.log in current directory
  -n            Number of tag to debug
  -o timestamp  Outpoint for cut command in miliseconds
  -p            Preserve mode only updates FLVs that have not been processed
                before
  -r            Recursion for directory processing
  -s            Simulation mode never writes FLV data to out-path
  -t path       Tagfile (MetaTags written in XML)
  -v            Verbose mode
  -x            XML mode instead of YAML mode
```

== Bug reports

norman.timmler@gmail.com

