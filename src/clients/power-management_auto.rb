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
# File:	clients/power-management_auto.ycp
# Package:	Configuration of power-management
# Summary:	Client for autoinstallation
# Authors:	Jiri Srain <jsrain@suse.cz>
#
# $Id$
#
# This is a client for autoinstallation. It takes its arguments,
# goes through the configuration and return the setting.
# Does not do any changes to the configuration.

# @param function to execute
# @param map/list of power-management settings
# @return [Hash] edited settings, Summary or boolean on success depending on called function
# @example map mm = $[ "FAIL_DELAY" : "77" ];
# @example map ret = WFM::CallFunction ("power-management_auto", [ "Summary", mm ]);
module Yast
  class PowerManagementAutoClient < Client
    def main
      Yast.import "UI"

      textdomain "power-management"

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("PowerManagement auto started")

      Yast.import "Mode"
      Yast.import "PowerManagement"
      Yast.include self, "power-management/wizards.rb"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      # Create a summary
      if @func == "Summary"
        @ret = Ops.get(PowerManagement.Summary, 0, "")
      # Reset configuration
      elsif @func == "Reset"
        PowerManagement.Import({})
        @ret = {}
      # Change configuration (run AutoSequence)
      elsif @func == "Change"
        @ret = PowerManagementAutoSequence()
      # Import configuration
      elsif @func == "Import"
        CreateNewSchemesMap(@param)
        @ret = PowerManagement.Import(@param)
      # Return actual state
      elsif @func == "Export"
        @ret = PowerManagement.Export
      # did configuration change
      elsif @func == "GetModified"
        @ret = PowerManagement.modified
      # set configuration as changed
      elsif @func == "SetModified"
        PowerManagement.modified = true
        @ret = true
      # Return needed packages
      elsif @func == "Packages"
        @ret = PowerManagement.AutoPackages
      # Read current state
      elsif @func == "Read"
        Yast.import "Progress"
        Progress.off
        @ret = PowerManagement.Read
        Progress.on
      # Write givven settings
      elsif @func == "Write"
        Yast.import "Progress"
        Progress.off
        PowerManagement.write_only = true
        @ret = PowerManagement.Write
        Progress.on
      else
        Builtins.y2error("Unknown function: %1", @func)
        @ret = false
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("PowerManagement auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end

    # Fill the new_schemes map so that schemes that weren't existing before
    # importing have their config file initialized before modifying it
    # @param [Hash] settings the import map
    def CreateNewSchemesMap(settings)
      settings = deep_copy(settings)
      return if !Mode.autoinst
      r_schemes = SCR.Dir(path(".sysconfig.powersave.schemes.section"))
      return if Builtins.size(r_schemes) == 0 # no scheme file to clone
      schemes = Ops.get_list(settings, "schemes", [])
      Builtins.foreach(schemes) do |s|
        id = Ops.get(s, "_scheme_id", "")
        if !Builtins.contains(r_schemes, id)
          Ops.set(PowerManagement.new_schemes, id, Ops.get(r_schemes, 0, ""))
        end
      end

      nil
    end
  end
end

Yast::PowerManagementAutoClient.new.main
