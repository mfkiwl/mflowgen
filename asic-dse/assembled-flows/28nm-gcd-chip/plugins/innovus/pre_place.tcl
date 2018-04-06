#=========================================================================
# pre_place.tcl
#=========================================================================
# This plug-in script is called before the corresponding Innovus flow step
#
#-------------------------------------------------------------------------
# Example tasks include:
#          - Power planning related tasks which includes
#            - Power planning for power domains (ring/strap creations)
#            - Power Shut-off cell power hookup
#-------------------------------------------------------------------------

specifyCellPad DFF* 2
reportCellPad -file $vars(rpt_dir)/place.cellpad.rpt

#-------------------------------------------------------------------------
# Global net connections for PG pins
#-------------------------------------------------------------------------

globalNetConnect VDD    -type pgpin -pin VDD    -inst * -verbose
globalNetConnect VDD    -type pgpin -pin VNW    -inst * -verbose
globalNetConnect VSS    -type pgpin -pin VSS    -inst * -verbose
globalNetConnect VSS    -type pgpin -pin VPW    -inst * -verbose
globalNetConnect VDDPST -type pgpin -pin VDDPST -inst * -verbose
globalNetConnect VSSPST -type pgpin -pin VSSPST -inst * -verbose
globalNetConnect POC    -type pgpin -pin POC    -inst * -verbose

# Create PG pins (temporary hardcoded) so that GDS export creates text for LVS in Calibre.

#createPGPin VDDPST -net VDDPST -geom AP 161.739 747.9425 165.874 752.7665
#createPGPin VDD -net VDD -geom AP 28.613 802.825 31.744 805.214
#createPGPin VSS -net VSS -geom AP 1242.699 799.185 1245.485 801.3795
#createPGPin VSSPST -net VSSPST -geom AP 1093.912 732.2075 1097.964 735.331
#createPGPin POC -net POC -geom M3 144.882 667.224 145.0805 667.392

add_gui_text -label VDDPST -pt { 160 750} -layer CUSTOM_BRG_LVS_AP -height 5
add_gui_text -label VDD    -pt {  30 805} -layer CUSTOM_BRG_LVS_AP -height 5
add_gui_text -label VSS    -pt {1245 800} -layer CUSTOM_BRG_LVS_AP -height 5
add_gui_text -label VSSPST -pt {1095 735} -layer CUSTOM_BRG_LVS_AP -height 5
add_gui_text -label POC    -pt { 145 667} -layer CUSTOM_BRG_LVS_M3 -height 5

#-------------------------------------------------------------------------
# M2 power rail preroute
#-------------------------------------------------------------------------
# ARM 28nm standard cells use 130nm width M2 rails. ARM suggests
# potentially prerouting a 250nm width M2 rail to improve IR drop and
# di/dt effects.

set M2_str_width 0.250

sroute -nets {VDD VSS} -corePinWidth $M2_str_width

#-------------------------------------------------------------------------
# M3 power stripe settings
#-------------------------------------------------------------------------
# ARM recommendations
#
# The ARM super user guide says that the 28nm standard cell libraries are
# designed to accommodate a 150nm wide metal3 strap with a horizontal
# VIA_Rect. To maximize the number of tracks available for signal routing
# on metal3, ARM also recommends the pitch of the metal3 straps to be a
# multiple of the signal routing pitch (100nm) and be offset to align the
# center of the metal3 straps exactly half way between signal routing
# tracks (50nm or half offset).
#
# We are using addStripe to add sets of stripes (a set includes both VSS
# and VDD).
#
# Set variables to space VSS and VDD straps evenly throughout the chip.
#
#     VSS    VDD    VSS
#     | |    | |    | |
#     | |    | |    | |
#     | |    | |    | |
#
#     _______ <---- $M3_str_pitch
#     ______________
#        ____   ^
#     ___  ^    |
#      ^   |    +-- $M3_str_interset_pitch
#      |   +------- $M3_str_intraset_spacing
#      +----------- $M3_str_width
#
# - M3_str_intraset_spacing : Space between VSS/VDD, chosen for constant
#                             pitch across all VSS and VDD stripes
# - M3_str_interset_pitch   : Pitch between same-signal stripes
#
# - M3_str_offset           : Offset from left edge of core to center the
#                             M3 stripe between vertical M3 routing tracks
#
# - M3_str_width            : ARM suggests 150nm
# - M3_str_pitch            : Choosing an arbitrary M3 pitch that is a
#                             multiple of M3 signal pitch for now

# Get M3 signal routing pitch as defined in the LEF

set M3_route_pitchX [dbGet [dbGetLayerByName M3].pitchX]

# Set M3 stripe variables

set M3_str_width            0.15
set M3_str_pitch            [expr 10  * $M3_route_pitchX]

set M3_str_intraset_spacing [expr $M3_str_pitch - $M3_str_width]
set M3_str_interset_pitch   [expr 2*$M3_str_pitch]

set M3_str_offset           [expr $M3_str_pitch + $M3_route_pitchX/2 - $M3_str_width/2]

setViaGenMode -reset
setViaGenMode -viarule_preference default
setViaGenMode -ignore_DRC false

setAddStripeMode -reset
setAddStripeMode -stacked_via_bottom_layer M2 \
                 -stacked_via_top_layer    M3

addStripe -nets {VSS VDD} -layer M3 -direction vertical \
    -width $M3_str_width                                \
    -spacing $M3_str_intraset_spacing                   \
    -set_to_set_distance $M3_str_interset_pitch         \
    -start_offset $M3_str_offset

# FIXME: use CPF?

#-------------------------------------------------------------------------
# Power ring
#-------------------------------------------------------------------------

addRing -nets {VDD VSS} -type core_rings -follow core   \
        -layer {top M8 bottom M8 left M9 right M9}      \
        -width $p_ring_width -spacing $p_ring_spacing   \
        -offset $p_ring_spacing                         \
        -extend_corner {tl tr bl br lt lb rt rb}

# Connect the ring to the IO pads

sroute                                  \
 -allowJogging 0                        \
 -connect padPin                        \
 -allowLayerChange 1                    \
 -layerChangeRange { M1 M9 }            \
 -nets { VDD VSS }                      \
 -padPinLayerRange { M1 M2 }            \
 -padPinPortConnect { allPort allGeom } \
 -padPinTarget { ring }

#-------------------------------------------------------------------------
# M8 power stripe settings
#-------------------------------------------------------------------------
# - M8_str_width            : ARM recommends 8X thickness compared to M3
# - M8_str_pitch            : Arbitrarily choosing the pitch between stripes
# - M8_str_intraset_spacing : Space between VSS/VDD, chosen for constant
#                             pitch across VSS and VDD stripes
# - M8_str_interset_pitch   : Pitch between same-signal stripes

set M8_str_width 1.20
set M8_str_pitch [expr 10 * $M3_str_pitch]

set M8_str_intraset_spacing [expr $M8_str_pitch - $M8_str_width]
set M8_str_interset_pitch   [expr 2*$M8_str_pitch]

setViaGenMode -reset
setViaGenMode -viarule_preference default
setViaGenMode -ignore_DRC false

setAddStripeMode -reset
setAddStripeMode -stacked_via_bottom_layer M3 \
                 -stacked_via_top_layer    M9

# Add the stripes
#
# Use -start to offset the stripes slightly away from the core edge.
# Allow same-layer jogs to connect stripes to the core ring if some
# blockage is in the way (e.g., connections from core ring to pads).
# Restrict any routing around blockages to use only layers for power.

addStripe -nets {VSS VDD} -layer M8 -direction horizontal \
    -width $M8_str_width                                  \
    -spacing $M8_str_intraset_spacing                     \
    -set_to_set_distance $M8_str_interset_pitch           \
    -max_same_layer_jog_length $M8_str_pitch              \
    -padcore_ring_bottom_layer_limit M8                   \
    -padcore_ring_top_layer_limit M9                      \
    -start [expr $M8_str_pitch]

#-------------------------------------------------------------------------
# M9 power stripe settings
#-------------------------------------------------------------------------
# - M9_str_width            : ARM recommends 16X thickness compared to M3
# - M9_str_pitch            : Arbitrarily choosing the pitch between stripes
# - M9_str_intraset_spacing : Space between VSS/VDD, chosen for constant
#                             pitch across VSS and VDD stripes
# - M9_str_interset_pitch   : Pitch between same-signal stripes

set M9_str_width 2.40 ; # ARM recommends 16X thickness compared to M3
set M9_str_pitch [expr 20 * $M3_str_pitch] ; # Arbitrarily choosing this

set M9_str_intraset_spacing [expr $M9_str_pitch - $M9_str_width]
set M9_str_interset_pitch   [expr 2*$M9_str_pitch]

setViaGenMode -reset
setViaGenMode -viarule_preference default
setViaGenMode -ignore_DRC false

setAddStripeMode -reset
setAddStripeMode -stacked_via_bottom_layer M8 \
                 -stacked_via_top_layer    M9

# Add the stripes
#
# Use -start to offset the stripes slightly away from the core edge.
# Allow same-layer jogs to connect stripes to the core ring if some
# blockage is in the way (e.g., connections from core ring to pads).
# Restrict any routing around blockages to use only layers for power.

addStripe -nets {VSS VDD} -layer M9 -direction vertical \
    -width $M9_str_width                                \
    -spacing $M9_str_intraset_spacing                   \
    -set_to_set_distance $M9_str_interset_pitch         \
    -max_same_layer_jog_length $M9_str_pitch            \
    -padcore_ring_bottom_layer_limit M8                 \
    -padcore_ring_top_layer_limit M9                    \
    -start [expr $M9_str_pitch/2]

