#!/usr/bin/env python
'''
    A python script example to create plot files to build a board:
    Gerber files
    Drill files
    Map dril files
    Important note:
        this python script does not plot frame references (page layout).
        the reason is it is not yet possible from a python script because plotting
        plot frame references needs loading the corresponding page layout file
        (.wks file) or the default template.
        This info (the page layout template) is not stored in the board, and therefore
        not available.
        Do not try to change SetPlotFrameRef(False) to SetPlotFrameRef(true)
        the result is the pcbnew lib will crash if you try to plot
        the unknown frame references template.
        Anyway, in gerber and drill files the page layout is not plot
'''

import sys

from pcbnew import *
project=sys.argv[1]
revision=sys.argv[2]
filename=project + ".kicad_pcb"
DocDir = "./Revision/" + revision + "/" + project + "/Documents/"

board = LoadBoard(filename)
pctl = PLOT_CONTROLLER(board)
popt = pctl.GetPlotOptions()
# pcbnew.PCB_PLOT_PARAMS Class Reference
#  SetAutoScale(aFlag)
#  SetExcludeEdgeLayer(aFlag)
#  SetMirror(aFlag)
#  SetNegative(aFlag)
#  SetPlotFrameRef(aFlag)
#  SetPlotInvisibleText(aFlag)
#  SetPlotPadsOnSilkLayer(aFlag)
#  SetPlotReference(aFlag)
#  SetPlotValue(aFlag)
#  SetPlotViaOnMaskLayer(aFlag)
# Set some important plot options:

popt.SetOutputDirectory(DocDir)

#non grayed out options for PDFs
popt.SetPlotFrameRef(False)
popt.SetPlotPadsOnSilkLayer(False)
popt.SetPlotValue(True)
popt.SetPlotReference(True)
popt.SetPlotInvisibleText(False)
popt.SetExcludeEdgeLayer(False)
popt.SetMirror(True)
popt.SetNegative(False)
popt.SetSubtractMaskFromSilk(False)
#popt.SetAutoScale(False)
#popt.SetUseGerberAttributes(False)
#popt.SetUseGerberProtelExtensions(False)
#popt.SetUseAuxOrigin(False)
#popt.SetPlotViaOnMaskLayer(False)
#popt.SetDrillMarksType("None")
popt.SetScale(1)
#popt.SetPlotMode("SKETCH")
#popt.SetPlotMode("FILLED")
popt.SetLineWidth(FromMM(0.1))

plot_plan = [
    ( "CuBottom", B_Cu, "Bottom layer" ),
    ( "SilkBottom", B_SilkS, "Silk top" ),
    ( "FabBottom", B_Fab, "Bottom Fabrication" ),
]

for layer_info in plot_plan:
    pctl.SetLayer(layer_info[1])
    pctl.OpenPlotfile(layer_info[0], PLOT_FORMAT_PDF, layer_info[2])
    print 'plot %s' % pctl.GetPlotFileName()
    if pctl.PlotLayer() == False:
        print "plot error"

pctl.ClosePlot()
