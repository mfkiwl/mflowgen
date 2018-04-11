#=========================================================================
# always_source.tcl
#=========================================================================
# This plug-in script is called from all Innovus flow scripts after
# loading setup.tcl.

#-------------------------------------------------------------------------
# Functions
#-------------------------------------------------------------------------

# Function to snap to track pitch

proc snapToTrackPitch {x} {
  global t_pitch
  return [expr [tcl::mathfunc::ceil [expr $x / $t_pitch] ] *  $t_pitch]
}


set t_pitch 0.56; # Pitch between m2 tracks (track pitch)
set r_pitch 3.92; # Pitch between power rails (standard cell height)

#-------------------------------------------------------------------------
# Floorplan variables
#-------------------------------------------------------------------------

set die_width   1130; # Die area width  1 mm
set die_height  2130; # Die area height 1 mm

#-------------------------------------------------------------------------
# IO pad floorplan
#-------------------------------------------------------------------------

# The die edge must have space for:
#
# 1. IO cell height (180nm IO library uses 115um height)
# 2. Extra margin for power routing
#
#           115         8.4
#             um         um
#     |----------------|---|----->
#     ^        ^         ^    ^
#     |        |         |    +----- Core area from here onward
#     |        |         +---------- Margin for power routing
#     |        +-------------------- IO cell height
#     |
#     +----------------------------- Die boundary
#
# Summing up from die boundary to core boundary:
#
#    25
# + 110
# +  90
# +   8.4
# -------
#    233.4
#
# Core width = 1000 - 233.4*2 = 533.2 um

set io_cell_len 115; # IO cell height (IO cell databook)

# Power ring

set pwr_net_list {VDD VSS}; # List of Power nets

# Power ring metal width and spacing

set p_ring_width   11.5; #
set p_ring_spacing 1.00; #

set p_ring_offset  5.0; # Bond pad sometimes requires a specific offset to avoid DRC

set core_margin_len [expr ([llength $pwr_net_list] * ($p_ring_width + $p_ring_spacing)) + $p_ring_offset]

# All boxes

set die_llx  0.00
set die_lly  0.00
set die_urx  $die_width
set die_ury  $die_height

set io_llx   $die_llx
set io_lly   $die_lly
set io_urx   $die_urx
set io_ury   $die_ury

set core_llx [expr               $io_cell_len + $core_margin_len]
set core_lly [expr               $io_cell_len + $core_margin_len]
set core_urx [expr $die_width  - $io_cell_len - $core_margin_len]
set core_ury [expr $die_height - $io_cell_len - $core_margin_len]

