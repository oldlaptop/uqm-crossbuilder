#! /usr/bin/env tclsh
#
# This script turns crossbuild.mk.in into a working makefile, as documented in
# that file's comment block. Tcl was chosen because why not (truly a
# time-honored reason).

if {[info exists env(CB_PREFIX)]} { if {[string length $env(CB_PREFIX)] > 0} {
	set CB_PREFIX $env(CB_PREFIX)
}} else {
	set CB_PREFIX .
}

set IN "$CB_PREFIX/crossbuild.mk.in"
set OUT "$CB_PREFIX/crossbuild.mk"

# expanded:
#	$(SH) $(CB_PREFIX)/crossbuild_lib<name>
#	touch $(STAMP_DIR)/lib<name>
set RULES "\t\$(SH) \$(CB_PREFIX)/crossbuild_&\n\ttouch \$(STAMP_DIR)/&"

set infile [open $IN r]
set outfile [open $OUT w]

puts $outfile "### AUTOMATICALLY GENERATED, EDIT crossbuild.mk.in AND RERUN mkgen.tcl ###\n\n"

while {![eof $infile]} {
	gets $infile line

	if {[string match "%*:*" $line]} {
		# strip out the leading %
		set line [string range $line 1 end]

		# pull out the name
		set target [string range $line 0 [expr [string first : $line] - 1]]

		# perform the &-replacement on dependencies
		set line "$target[string map {& \$(STAMP_DIR)/} [string range $line [string first : $line] end]]"
		set rules [string map "& $target" $RULES]

		puts $outfile "\$(STAMP_DIR)/$target\: $target"
		puts $outfile $line
		puts $outfile $rules
	} else {
		puts $outfile $line
	}
}
