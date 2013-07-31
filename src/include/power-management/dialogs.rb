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
# File:	include/power-management/dialogs.ycp
# Package:	Configuration of power-management
# Summary:	Dialogs definitions
# Authors:	Jiri Srain <jsrain@suse.cz>
#
# $Id$
module Yast
  module PowerManagementDialogsInclude
    def initialize_power_management_dialogs(include_target)
      Yast.import "UI"

      textdomain "power-management"

      Yast.import "CWM"
      Yast.import "Label"
      Yast.import "Mode"
      Yast.import "Popup"
      Yast.import "PowerManagement"
      Yast.import "Wizard"

      Yast.include include_target, "power-management/widgets.rb"
    end

    # Return a modification status
    # @return true if data was modified
    def Modified
      PowerManagement.Modified
    end

    # Ask if Abort if modified
    # @return [Boolean] true if answered Yes
    def ReallyAbort
      !PowerManagement.Modified || Popup.ReallyAbort(true)
    end

    # Ask if Abort
    # @return [Boolean] true if answered Yes
    def AskAbort
      Popup.ReallyAbort(true)
    end

    # Check for Abort
    # @return [Boolean] true if was pushed
    def PollAbort
      UI.PollInput == :abort
    end

    # Check for Abort durign read
    # @return [Boolean] true if was pushed
    def ReadAbort
      PollAbort() && AskAbort()
    end

    # Check for Abort durign write
    # @return [Boolean] true if was pushed
    def WriteAbort
      # yes-no popup
      PollAbort() &&
        Popup.YesNo(
          _(
            "If you abort writing now, the saved\n" +
              "settings may be inconsistent.\n" +
              "Really abort?"
          )
        )
    end

    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Builtins.y2milestone("Running read dialog")
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      PowerManagement.AbortFunction = fun_ref(method(:ReadAbort), "boolean ()")
      ret = PowerManagement.Read
      ret ? :next : :abort
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Builtins.y2milestone("Running write dialog")
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      PowerManagement.AbortFunction = fun_ref(method(:WriteAbort), "boolean ()")
      ret = PowerManagement.Write
      ret ? :next : :abort
    end

    # Run dialog for ACPI buttons behavior configuration
    # @return [Symbol] for wizard sequencer
    def MainDialog
      Builtins.y2milestone("Running main dialog")

      contents = HBox(
        HStretch(),
        VBox(VStretch(), "scheme_selection", VStretch()),
        HStretch()
      )

      # dialog caption
      caption = _("Power Management Settings")
      widget_names = ["scheme_selection"]

      w = CWM.CreateWidgets(widget_names, @widgets)
      help = CWM.MergeHelps(w)
      contents = CWM.PrepareDialog(contents, w)
      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.FinishButton
      )
      Wizard.HideBackButton
      Wizard.SetAbortButton(:abort, Label.CancelButton)
      CWM.Run(w, { :abort => fun_ref(method(:ReallyAbort), "boolean ()") })
    end

    # Run dialog for schemes configuration
    # @return [Symbol] for wizard sequencer
    def SchemesDialog
      Builtins.y2milestone("Running schemes management dialog")

      contents = HBox(
        HSpacing(2),
        VBox(VSpacing(2), "schemes_list", VSpacing(2)),
        HSpacing(2)
      )

      # dialog caption
      caption = _("Power Management Profile Setup")

      CWM.ShowAndRun(
        {
          "widget_names"       => ["schemes_list"],
          "widget_descr"       => @widgets,
          "contents"           => contents,
          "caption"            => caption,
          "back_button"        => Label.BackButton,
          "next_button"        => Label.OKButton,
          "fallback_functions" => {
            :abort => fun_ref(method(:AskAbort), "boolean ()")
          }
        }
      )
    end

    # Run dialog for single scheme configuration
    # @return [Symbol] for wizard sequencer
    def SchemeDialog1
      Builtins.y2milestone("Running single scheme management dialog part 1")

      contents = HBox(
        HSpacing(2),
        VBox(VStretch(), "scheme_name", VSpacing(1), "scheme_descr", VStretch()),
        HSpacing(2)
      )

      # dialog caption
      caption = _("Power Management Profile Setup")

      CWM.ShowAndRun(
        {
          "widget_names"       => ["scheme_name", "scheme_descr"],
          "widget_descr"       => @widgets,
          "contents"           => contents,
          "caption"            => caption,
          "back_button"        => Label.BackButton,
          "next_button"        => Label.NextButton,
          "fallback_functions" => {
            :abort => fun_ref(method(:AskAbort), "boolean ()")
          }
        }
      )
    end

    # Run dialog for single scheme configuration
    # @return [Symbol] for wizard sequencer
    def SchemeDialog2
      Builtins.y2milestone("Running single scheme management dialog part 1")

      contents = HBox(
        HStretch(),
        VBox(VStretch(), "hard_disk", VStretch(), "cpu", VStretch()),
        HStretch()
      )

      # dialog caption
      caption = _("Power Management Profile Setup")

      CWM.ShowAndRun(
        {
          "widget_names"       => ["hard_disk", "cpu"],
          "widget_descr"       => @widgets,
          "contents"           => contents,
          "caption"            => caption,
          "back_button"        => Label.BackButton,
          "next_button"        => Label.NextButton,
          "fallback_functions" => {
            :abort => fun_ref(method(:AskAbort), "boolean ()")
          }
        }
      )
    end



    # pseudo dialogs

    # Fetch all schemes
    # @return [Symbol] always `mext
    def FetchSchemes
      PowerManagement.FetchSchemes
      :next
    end

    # Store all schemes
    # @return [Symbol] always `mext
    def StoreSchemes
      PowerManagement.StoreSchemes
      :next
    end

    # Store current scheme
    # @return [Symbol] always `mext
    def StoreScheme
      PowerManagement.StoreScheme
      :next
    end
  end
end
