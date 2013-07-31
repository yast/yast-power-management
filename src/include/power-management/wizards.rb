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
# File:	include/power-management/wizards.ycp
# Package:	Configuration of power-management
# Summary:	Wizards definitions
# Authors:	Jiri Srain <jsrain@suse.cz>
#
# $Id$
module Yast
  module PowerManagementWizardsInclude
    def initialize_power_management_wizards(include_target)
      Yast.import "UI"

      textdomain "power-management"

      Yast.import "Label"
      Yast.import "Sequencer"
      Yast.import "Wizard"

      Yast.include include_target, "power-management/dialogs.rb"
    end

    # Schemes management workflow of the power management configuration
    # @return sequence result
    def SchemesSequence
      aliases =
        #	"scheme3"		:   ``( SchemeDialog3 ()),
        {
          "fetch"        => [lambda { FetchSchemes() }, true],
          "store"        => [lambda { StoreSchemes() }, true],
          "store_scheme" => [lambda { StoreScheme() }, true],
          "main"         => lambda { SchemesDialog() },
          "scheme1"      => lambda { SchemeDialog1() },
          "scheme2"      => lambda { SchemeDialog2() }
        }

      sequence = {
        "ws_start"     => "fetch",
        "fetch"        => { :next => "main" },
        "main"         => {
          :abort => :abort,
          :next  => "store",
          :add   => "scheme1",
          :edit  => "scheme1"
        },
        "store"        => { :next => :next },
        "scheme1"      => { :abort => :abort, :next => "scheme2" },
        "scheme2" =>
          #	    `next		: "scheme3",
          { :abort => :abort, :next => "store_scheme" },
        # "scheme3" : $[
        # 	    `abort		: `abort,
        # 	    `next		: "store_scheme",
        # 	],
        "store_scheme" => {
          :next => "main"
        }
      }

      ret = Sequencer.Run(aliases, sequence)

      ret
    end


    # Main workflow of the power-management configuration
    # @return sequence result
    def MainSequence
      aliases = { "main" => lambda { MainDialog() }, "schemes_sequence" => lambda(
      ) do
        SchemesSequence()
      end }

      sequence = {
        "ws_start"         => "main",
        "main"             => {
          :abort        => :abort,
          :next         => :next,
          :schemes_edit => "schemes_sequence"
        },
        "schemes_sequence" => { :abort => :abort, :next => "main" }
      }

      ret = Sequencer.Run(aliases, sequence)

      ret
    end

    # Whole configuration of power-management
    # @return sequence result
    def PowerManagementSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopIcon("power-management")
      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      ret
    end

    # Whole configuration of power-management but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def PowerManagementAutoSequence
      # Initialization dialog caption
      caption = _("Power Management Configuration")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetDesktopIcon("power-management")
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = MainSequence()

      UI.CloseDialog
      ret
    end
  end
end
