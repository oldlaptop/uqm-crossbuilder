#! /usr/bin/python3

import os
import glob

# var script_path
#
# The location of the crossbuild_libfoo shellscripts we'll be working with
script_path = "/usr/src/crossbuild/"

def build_pkgdict ():
	'''
	Returns a dict of package names and the paths of their
	script files.
	'''
	return {os.path.basename (path)[11:]:path for path in glob.iglob (os.path.join (script_path, "crossbuild_*"))}

def build_depsdict (pkgdict):
	'''
	Returns a dict of package names and lists of their dependencies' names
	e.g. {'libpng': ['zlib']}
	'''
	pkgnames = pkgdict.keys ()
	pkgnames = list (pkgnames)
	
	depsdict = {name:[] for name in pkgnames}
	
	# We will now iterate through all packages, searching each package's script file for @DEP@ tokens.
	# For the moment this process is not robust, we expect the package name to always follow
	# one character after the @DEP@ token, and we expect the line to end with the package name.
	# Strange things will happen if this format is not adhered to strictly.
	#
	# TODO: do this the *right* way, with actual proper parsing :P
	for key in pkgnames:
		with open (pkgdict[key], encoding='utf-8') as pkgfile:
			for cur_line in pkgfile:
				try:
					depsdict[key].append (cur_line[(cur_line.index ('@DEP@') + 6):-1])
				except ValueError:
					continue
	return depsdict


if __name__ == '__main__':
	script_path = "."
	pkgdict = build_pkgdict ()
	depsdict = build_depsdict (pkgdict)
	print(pkgdict)
	print(depsdict)
