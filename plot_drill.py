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

board = LoadBoard(filename)

DrillDir = "./Revision/" + revision + "/" + project + "/TR/DRILL/"
DocDir = "./Revision/" + revision + "/" + project + "/Documents/"

#pctl = PLOT_CONTROLLER(board)
#popt = pctl.GetPlotOptions()
#popt.SetOutputDirectory(DrillDir)
# likely don't need to do any plot options, but just incase...
# Set some important plot options:
#popt.SetPlotFrameRef(False)
#popt.SetLineWidth(FromMM(0.35))
#popt.SetAutoScale(False)
#popt.SetScale(1)
#popt.SetMirror(False)
#popt.SetUseGerberAttributes(True)
#popt.SetUseGerberProtelExtensions(False)
#popt.SetExcludeEdgeLayer(True);
#popt.SetUseAuxOrigin(True)
#popt.SetPlotValue(False)
#popt.SetPlotReference(False)
#popt.SetSubtractMaskFromSilk(False)
#pctl.ClosePlot()

# Fabricators need drill files.
# sometimes a drill map file is asked (for verification purpose)
# offset is the origin of the file
# mirror True to generate a Back side image
# mirror False to generate a Front side image
# mergeNPTH True to generate only one drill file
# mergeNPTH False to generate 2 separate drill files (one for plated holes, one for non plated holes)
mirror = False
minimalHeader = False
offset = board.GetAuxOrigin()
mergeNPTH = False
metricFmt = True
genDrl = True
genMap = True
ReportFileName = DocDir + 'drill_report.txt'

print 'create drill and map files in %s' % DrillDir
print 'report: %s' % ReportFileName
drlwriter = EXCELLON_WRITER( board )
drlwriter.SetMapFileFormat( PLOT_FORMAT_PDF )
drlwriter.SetOptions( mirror, minimalHeader, offset, mergeNPTH )
drlwriter.SetFormat( metricFmt )
drlwriter.CreateDrillandMapFilesSet( DrillDir, genDrl, genMap );
drlwriter.GenDrillReportFile( ReportFileName );
