# gcov.vim

This plugin provides a simple way to build load and reload gcov files for an open
source file. It will highlight the covered and uncovered lines and branches.

![Screenshot](/img/screenshot.png)

The screenshot shows various cases for line and branch coverage:
* (✓) line covered -- line has been executed at least once
* (✘) line uncovered -- line has not been executed
* (✓✓) branch covered -- all branch directions has been taken at least once
* (✓✘) branch partly covered -- some but not all branch directions has been taken at least once
* (✘✘) branch uncovered -- none of the branch directions has been executed

This plugin is based on [m42e/vim-gcov-marker](https://github.com/m42e/vim-gcov-marker)

## Install

If you use Vundle plugin manager for vim then auto-gcov-marker can be installed by adding

```vimrc
Plugin 'm-abubakar/gcov.vim'
```
to your vimrc and running
```
PluginInstall
```

## Usage

Assuming that your tests has been built with coverage support, just run
```
GcovBuild
```
and coverage information should appear in your vim sign column.
Under the hood this plugin recursively searches for gcno file and calls `gcov` for it, if it succeeds - generated gcov file is used for showing coverage information.
Note that plugin assumes that gcov is present on your system.

In order to clear coverage information run:
```
GcovClear
```
command.

If you would like to specify exact gcov file to use:
```
GcovLoad <filename>.gcov
```
Note that plugin expects gcov files in intermediate format.


## Example

A simple example for test purposes is provided in `test` directory.
After installing the plugin - go to provided test direcory, build and run:
```bash
cd path/to/test/directory/
make
./test
```

Open `test.c` file in vim and issue a command:
```vimrc
:GcovBuild
```

Now You should see something similar to what is provided in the screenshot.


## Configuration

Default markers can be customized using the variables below.
```vimrc
let g:auto_gcov_marker_line_covered = '✓'
let g:auto_gcov_marker_line_uncovered = '✘'
let g:auto_gcov_marker_branch_covered = '✓✓'
let g:auto_gcov_marker_branch_partly_covered = '✓✘'
let g:auto_gcov_marker_branch_uncovered = '✘✘'

```

By default GcovBuild searches for gcna and gcno files recursively from vim working directory, but this can be customized with following parameter:
```vimrc
let g:auto_gcov_marker_gcno_path  = 'path/to/gcno/files/'
```

Generated gcov files by default are put in vim working directory also.
This might clutter working directory - therefore it is recommended to create seperate directory for gcov files.
After creating empty directory configure plugin to use it:
```vimrc
let g:auto_gcov_marker_gcov_path  = 'path/to/gcov/files/'
```

