# Bash shell-script Utilities

A collection of Bash utility shell-scripts that I thought _must_ be useful to others.

#### naming conventions
Scripts which are intended to be run from the command-line are marked as executable. Generally, those which are not intended to run from the command line use the .sh suffix. They, of course, can still be run by invoking them via the shell command:
```
$SHELL myscript.sh
```
When this writeup describes the usage of a script, parameters in brackets […],
indicated optional parameters.

## _include.sh
Common settings and functions for use in other scripts so that I don't have to keep rewriting this stuff for every script. It turns out that I don't use it as much as I thought I would, because I don't like to have too many dependencies in scripts.
- ANSI color settings
- `echo_tabs_align()`
- `echo_align_column()` — Output text padded with tabs necessary to create a fixed-width "column".
- `is_command()` — A silent (and consistent way) to determine if the specified command is accessible.

## deldiff
Delete duplicate files from this "current" or "remote" directory. This
iterates over all files in the current directory, looking for matches in the
remote directory (based on files of the same name). Matches are determined
by diff'ing the files. Matching files are deleted from either the current
or remote directory; you are prompted before deleting begins.
```
deldiff [switches] {remote_directory}
```
<dl>
   <dt><em>remote_directory</em><dd>is a relative or absolute directory path.
   <dt>switches are:
   <dd><dl>
 	<dt>-c<dd>No prompt which directory to delete files from, delete the ones in the "current" directory.
  	<dt>-r<dd>No prompt which directory to delete files from, delete the ones in the "remote" directory.
	<dt>-t<dd>"Test" only... do not delete any files.
	<dt>-n<dd>"No test", simply prompt (unless `-c` or `-r` are set) which directory to delete from.
</dl></dl>

## delemptydirs
Remove empty directories under the specified dir (or current dir)

## kurl.sh
Provides functions to perform `curl` command calls, returning HTTP response
data and the http response code. You can call this script from the command line to run curl from the command line in a different manner and/or to see how the functions will perform within another script.

## lpath
List the path components of an environment variable (default uses PATH).
```
lpath [ env_var ]
```
<dl>
	<dt>env_var<dd>Name of the environment variable to list paths of (default, PATH)
</dl>

## ssh-addauth
Add specified .pub key to remote server
```
ssh-addauth [ -i priv_key.pem ] [host] public_key_file...
```
<dl>
	<dt>remote<dd>Remote server (as would be specified to ssh)
	<dt>public_key_file<dd>normally a .pub file.
</dl>

## ssh-list
A pretty list of ssh keys that this login has enabled for access (as indicated by `authorized_keys`).

## touchdir
Set directory's time/date based on the newest content within it. 
```
touchdir [switches] [target-dir]
```
<dl>
	<dt>target-dir<dd>The directory to set. Default is `.`
	<dt>-a<dd>Check "all" files, i.e., dot-files, for latest date/time.
	<dt>-r<dd>Recurse, setting all directories' date/times within the target directory tree.
</dl>
