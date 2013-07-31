# encoding: utf-8

# ***************************************************************************
#
# Copyright (c) 2000 - 2010 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************
# File:	clients/power-management.ycp
# Package:	Configuration of power-management
# Summary:	Main file
# Authors:	Jiri Srain <jsrain@suse.cz>
#
# $Id$
#
# Main file for power-management configuration. Uses all other files.
module Yast
  class PowerManagementClient < Client
    def main
      Yast.import "UI"

      #**
      # <h3>Configuration of power-management</h3>

      textdomain "power-management"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("PowerManagement module started")

      Yast.import "CommandLine"
      Yast.include self, "power-management/wizards.rb"

      Yast.include self, "power-management/commandline.rb"


      # map cmdline_description = $[
      #     "id"	: "power-management",
      #     // Command line help text for the Xpower-management module
      #     "help"	: _("Configuration of power management"),
      #     "guihandler"        : PowerManagementSequence,
      #     "initialize"        : PowerManagement::Read,
      #     "finish"            : PowerManagement::Write,
      #     "actions"           : $[
      #     ],
      #     "options"		: $[
      #     ],
      #     "mapping"		: $[
      #     ]
      # ];

      # main ui function
      @ret = CommandLine.Run(@cmdline)
      Builtins.y2debug("ret=%1", @ret)

      # Finish
      Builtins.y2milestone("PowerManagement module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end

    # CommandLine handler for running GUI
    # @return [Boolean] true if settings were saved
    def GuiHandler
      ret = PowerManagementSequence()
      return false if ret == :abort || ret == :back || ret == :nil
      true
    end
  end
end

Yast::PowerManagementClient.new.main
