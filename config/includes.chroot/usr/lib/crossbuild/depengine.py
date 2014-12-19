#! /usr/bin/env python3

import os
import glob

# var script_path
#
# The location of the crossbuild_libfoo shellscripts we'll be working with
script_path = "/usr/lib/crossbuild/"

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

def build_install_list (pkgdict, depsdict, wanted_list):
	'''
	Builds the list of packages to be installed, based on dependencies of package names
	found in wanted_list. Sorting is done in terms of installation order; packages will
	be placed after all their dependencies.
	'''
	
	# First we will determine a list of all packages to be installed, pruning duplicates
	# (dependencies required by multiple packages, dependencies already specified in
	# wanted_list, etc. We first make a duplicate-less copy of wanted_list, then iterate
	# repeatedly through all members in the copy, adding their dependencies to the copy
	# if they are not already present, until the loop runs once without altering the copy.
	# (We unfortunately cannot do the elegant thing and use comprehensions for this, since
	# the loop must reference the structure it's modifying, and doing this from inside a
	# comprehension is horribly ugly, defeating the purpose. Python also really should have
	# a do ... while analog, as it is we need an ugly hack for that as well...)
	
	# First make the pruned copy
	install_list = []
	for pkgname in wanted_list:
		if pkgname not in install_list:
			install_list.append (pkgname)
	# Now add dependencies
	while True:
		modified_this_run = False
		for pkgname in install_list:
			for candidate in depsdict[pkgname]:
				if candidate not in install_list:
					install_list.insert (0, candidate)
					modified_this_run = True
				else:
					# If the package comes before its dependency in the installation
					# order, we need to fix this. (Note that we rely upon the previous
					# measures to ensure there are no duplicates in the list, a bug which
					# causes duplicates to be present at this point could cause another
					# bug here...
					if install_list.index (pkgname) < install_list.index (candidate):
						install_list.pop (install_list.index (candidate))
						install_list.insert (install_list.index (pkgname), candidate)
						modified_this_run = True
		if modified_this_run == False:
			break
	return install_list

if __name__ == '__main__':
	import argparse
	
	parser = argparse.ArgumentParser (description='Print to stdio a \'\\n\'-delimited list of script files to be run in order to crossbuild the given packages')
	parser.add_argument ('packages', metavar='package', nargs='+', help='A package you want given in the list')
	args = parser.parse_args ()
	
	pkgdict = build_pkgdict ()
	depsdict = build_depsdict (pkgdict)
	install_list = build_install_list (pkgdict, depsdict, args.packages)
	
	for pkgname in install_list:
		print (pkgdict[pkgname])
	#print (pkgdict)
	#print (depsdict)
	#print (install_list)
