#!/bin/bash

CARD_SINK="USB Audio Device"
CARD_SOURCE="USB Audio Device"

#carla_filter_output "../Carla/Carla_${name}.carxp"
#carla_filter_input  "../Carla/Carla_${name}_mic.carxp"


# ~/.calfpresets
# autoconnect does not work with pipewire 0.3.51
calf_filter_output --load "../Calf/${name}.xml"

#calf_filter_output eq12:'Sades SA903 2023-01-27' ! compressor:'c1'

calf_filter_input --load "../Calf/${name}_MIC.xml"
