#!/usr/bin/env python
# -*- coding: utf-8 -*-
# generated by wxGlade 0.6.3 on Mon Feb  2 17:14:45 2015

import wx
from sqlobject import connectionForURI
from TinyhebFrame import TinyhebFrame

class TinyhebApp(wx.App):
    def OnInit(self):
        # Database
        self.db = connectionForURI('sqlite:/:memory:')

        # GUI
        wx.InitAllImageHandlers()
        tinyheb_frame = TinyhebFrame(None, -1, "")
        self.SetTopWindow(tinyheb_frame)
        tinyheb_frame.Show()
        return 1

# end of class TinyhebApp

if __name__ == "__main__":
    tinyheb = TinyhebApp(0)
    tinyheb.MainLoop()
