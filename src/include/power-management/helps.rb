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
# File:	include/power-management/helps.ycp
# Package:	Configuration of power-management
# Summary:	Help texts of all the dialogs
# Authors:	Jiri Srain <jsrain@suse.cz>
#
# $Id$
module Yast
  module PowerManagementHelpsInclude
    def initialize_power_management_helps(include_target)
      textdomain "power-management"

      # All helps are here
      @HELPS = {
        # Read dialog help 1/2
        "read"             => _(
          "<p><b><big>Initializing Power Management Configuration</big></b><br>\nPlease wait...<br></p>"
        ) +
          # Read dialog help 2/2
          _(
            "<p><b><big>Aborting Initialization</big></b><br>\nSafely abort the configuration utility by pressing <b>Abort</b> now.</p>"
          ),
        # Write dialog help 1/2
        "write"            => _(
          "<p><b><big>Saving Power Management Configuration</big></b><br>\nPlease wait...<br></p>"
        ) +
          # Write dialog help 2/2
          _(
            "<p><b><big>Aborting Saving</big></b><br>\nAbort the save procedure by pressing <b>Abort</b>.</p>"
          ),
        # Main dialog help 1/3
        "scheme_selection" => _(
          "<p><b><big>Energy Saving Profiles</big></b><br>\nUse <b>Selected Profile</b> to adjust the energy saving profile to use.</p>"
        ) +
          # Main dialog help 2/3
          _("<p>Below the selected profile, its description is displayed.</p>") +
          # Main dialog help 3/3
          _(
            "<p>To read more about pm-profiler and to learn how to create or modify\n" +
              "the power saving profiles, refer to the\n" +
              "<i>/usr/share/doc/packages/pm-profiler/README</i> file.</p>"
          ),
        #     +
        #     // Main dialog help 3/5
        #     _("<p><b><big>Adjusting Energy Saving Profiles</big></b><br>
        # To adjust energy saving profiles, delete existing ones, or create new ones,
        # use <b>Edit Profiles</b>.</p>")




        # Schemes list dialog 1/3
        "profiles_list"    => _(
          "<p><b><big>Profile Setup</big></b><br>\n" +
            "Adjust the energy saving profiles. To modify a profile, select\n" +
            "it and click <b>Edit</b>.</p>\n"
        ) +
          # Schemes list dialog 2/3
          _(
            "<p>To add a new profile, select a profile to clone then click\n" +
              "<b>Add</b>. To delete an existing profile, select it and click \n" +
              "<b>Delete</b>.</p>"
          ) +
          # Profiles list dialog 3/3
          _(
            "<p>In the main dialog, assign profiles to use when you \nwork on battery or AC power.</p>"
          ),
        # Profile editation dialog 1 help 1/6
        "profile_name"     => _(
          "<p><big><b>Profile Setup</b></big>\n" +
            "Configure the settings of the profile. Enter its name in <b>Profile Name</b>\n" +
            "and optionally a description in <b>Profile Description</b>.</p>"
        ),
        # Profile editation dialog 1 help 2/6
        # rwalter merged content into previous. sorry.
        "profile_descr"    => "",
        # Profile editation dialog 2 help 1/2
        "hard_disk"        => _(
          "<p><b><big>Hard Disk Settings</big></b><br>\n" +
            "Use <b>Standby Policy</b> to adjust the power saving policy of the hard disks.\n" +
            "Remember that more power saving also means waiting more often until the disk\n" +
            "drive is ready.\n" +
            "Use <b>Acoustic Policy</b> to adjust the acoustic policy of the disk. The noise\n" +
            "produced by the disk may be lowered by moving disk heads more slowly. Not all\n" +
            "disks support this feature.</p>"
        ),
        # Profile editation dialog 2 help 2/2
        "cpu"              => _(
          "<p><b><big>Cooling Policy</big></b><br>\n" +
            "Use the cooling policy <b>Status</b> to adjust the active or passive cooling policy.\n" +
            "Active means that the cooling fan is\n" +
            "turned on if the system starts overheating.\n" +
            "If the system continues overheating, the CPU frequency and voltage are\n" +
            "reduced. Passive means that the system first reduces frequency then, if\n" +
            "that does not help, turns the cooling fan on.</p>\n" +
            "<p>To specify actions to perform when the system overheats\n" +
            "or reaches critical temperature, use <b>Overheat Temperature Action</b> and\n" +
            "<b>Critical Temperature Action</b>.</p>"
        )
      } 

      # EOF
    end
  end
end
