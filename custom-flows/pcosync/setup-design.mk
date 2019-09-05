#=========================================================================
# setup-design.mk
#=========================================================================
# Here we select the design to push as well as its top-level Verilog
# module name, the clock target, and the Verilog source file.

#-------------------------------------------------------------------------
# Design
#-------------------------------------------------------------------------

design_name  = correlator_top
clock_period = 50.0
design_v     = /research/APSEL/ib264/work/rtl/top.v

#-------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------

export design_name


