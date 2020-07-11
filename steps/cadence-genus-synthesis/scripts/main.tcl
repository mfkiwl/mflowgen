set dc_design_name                $::env(design_name)
set dc_clock_period               $::env(clock_period)
set dc_gate_clock                 $::env(gate_clock)
set dc_uniquify_with_design_name  $::env(uniquify_with_design_name)

set_db common_ui false

if { $dc_gate_clock == True } {
  set_attr lp_insert_clock_gating true
}
 
set_attr library    [join "
                      [glob -nocomplain inputs/*.lib]
                      [glob -nocomplain inputs/adk/*.lib]
                    "]

set_attr lef_library [join "
                       [glob -nocomplain inputs/*.lef]
                       [glob -nocomplain inputs/adk/*.lef]
                     "]

set_attr qrc_tech_file [list inputs/adk/pdk-typical-qrcTechFile]

read_hdl -sv [glob -directory inputs -type f *.v *.sv]
elaborate $::env(design_name)

source "inputs/adk/adk.tcl"

source -verbose "inputs/constraints.tcl"

if { $dc_uniquify_with_design_name == True } {
  set_attr uniquify_naming_style "${dc_design_name}_%s_%d"
  uniquify $::env(design_name)
}

set_attribute avoid true [get_lib_cells {*/E* */G* *D16* *D20* *D24* *D28* *D32* SDF* *DFM*}]
# don't use Scan enable D flip flops
set_attribute avoid true [get_lib_cells {*SEDF*}]

syn_gen
set_attr syn_map_effort high
syn_map
syn_opt 

write_snapshot -directory results_syn -tag final
write_design -innovus -basename results_syn/syn_out

write_name_mapping

