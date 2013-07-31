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
  module PowerManagementCommandlineInclude
    def initialize_power_management_commandline(include_target)
      Yast.import "CommandLine"
      Yast.import "PowerManagement"

      textdomain "power-management"

      @cmdline = {
        "id"         => "power-management",
        # command line help text for power management module
        "help"       => _(
          "Power management configuration module"
        ),
        "guihandler" => fun_ref(method(:GuiHandler), "boolean ()"),
        "initialize" => fun_ref(PowerManagement.method(:Read), "boolean ()"),
        "finish"     => fun_ref(PowerManagement.method(:Write), "boolean ()"),
        "actions" =>
          # 	"profile" : $[
          # 	    "handler"	: SchemeHandler,
          # 	    // command line help text for an action
          # 	    "help"	: _("Set options of a profile"),
          # 	],
          {
            "print" => {
              "handler" => fun_ref(method(:PrintHandler), "boolean (map)"),
              # command line help text for an action
              "help"    => _(
                "Display current settings"
              )
            },
            "set"   => {
              "handler" => fun_ref(method(:SetHandler), "boolean (map)"),
              # command line help text for an action
              "help"    => _(
                "Set general settings"
              )
            }
          },
        "options"    => {
          "profile"          => {
            "type" => "string",
            # command line help text for an option
            "help" => _(
              "Display only specified profile"
            )
          },
          "selected_profile" => {
            # command line help text for an option
            "help" => _(
              "Display only profile selected for use"
            )
          },
          "profile"          => {
            # command line help text for an option
            "help" => _(
              "Profile to be used"
            ),
            "type" => "string"
          },
          "name"             => {
            # command line help text for an option
            "help" => _(
              "The profile name"
            ),
            "type" => "string"
          },
          "add"              => {
            # command line help text for an option
            "help" => _(
              "Add a new profile"
            )
          },
          "edit"             => {
            # command line help text for an option
            "help" => _(
              "Edit an existing profile"
            )
          },
          "delete"           => {
            # command line help text for an option
            "help" => _(
              "Remove an existing profile"
            )
          },
          "description"      => {
            # command line help text for an option
            "help" => _(
              "The description of the profile"
            ),
            "type" => "string"
          },
          "clone"            => {
            # command line help text for an option
            "help" => _(
              "The profile to clone"
            ),
            "type" => "string"
          },
          "option"           => {
            # command line help text for an option
            "help" => _(
              "Option of a profile to modify"
            ),
            "type" => "string"
          },
          "value"            => {
            # command line help text for an option
            "help" => _(
              "Value of the specified option to set"
            ),
            "type" => "string"
          },
          "rename"           => {
            # command line help text for an option
            "help" => _(
              "New name of the profile to rename"
            ),
            "type" => "string"
          }
        },
        "mappings" =>
          #	"profile"	: ["add", "edit", "delete", "name", "description",
          #				"clone", "option", "value", "rename"],
          {
            #	"print"		: [ "selected_profile", "profile", ],
            "print" => [],
            "set"   => ["profile"]
          }
      }
    end

    # Handler for command line interface
    # @param [Hash] options map options from the command line
    # @return [Boolean] true if settings have been changed
    def PrintHandler(options)
      options = deep_copy(options)
      print_all = true
      printed = false
      #     boolean print_all = false;
      #     if (! (haskey (options, "selected_profile")
      # 	|| haskey (options, "profile")))
      #     {
      # 	print_all = true;
      #     }
      #     if (print_all || haskey (options, "profile"))
      #     {
      # 	string scheme = options["profile"]:"";
      # 	boolean all_schemes = print_all || scheme == "";
      # 	foreach (map<string,string> s, PowerManagement::schemes, {
      # 	    if (all_schemes || s["SCHEME_NAME"]:"" == scheme)
      # 	    {
      # 		if (printed)
      # 		    CommandLine::Print ("\n");
      # 		// cmdline output, %1 is scheme name
      # 		CommandLine::Print (sformat (_("Profile Name: %1"),
      # 		    s["SCHEME_NAME"]:""));
      # 		// cmdline output, %1 is scheme description
      # 		CommandLine::Print (sformat (_("Profile Description: %1"),
      # 		    s["SCHEME_DESCRIPTION"]:""));
      # 		foreach (string k, string v, s, {
      # 		    if (k != "SCHEME_NAME" && k != "SCHEME_DESCRIPTION"
      # 			&& substring (k, 0, 1) != "_")
      # 		    {
      # 			CommandLine::Print (sformat ("%1: %2", k, v));
      #
      # 		    }
      # 		});
      # 		printed = true;
      # 	    }
      # 	});
      #     }
      if print_all || Builtins.haskey(options, "selected_profile")
        CommandLine.Print("\n") if printed
        # header for commandline output
        CommandLine.Print(_("Power Saving Profiles:\n"))
        scheme = Ops.get(PowerManagement.global_settings, "SCHEME", "")
        scheme = _("Default Profile") if scheme == ""
        Builtins.foreach(PowerManagement.schemes) do |s|
          if Ops.get(s, "_scheme_id", "") == scheme
            scheme = Ops.get(s, "SCHEME_NAME", scheme)
            next
          end
        end
        scheme = PowerManagement.TranslateSchemeName(scheme)
        CommandLine.Print(Builtins.sformat(_("Selected Profile: %1"), scheme))
        available = Builtins.maplist(PowerManagement.schemes) do |s|
          PowerManagement.TranslateSchemeName(Ops.get(s, "SCHEME_NAME"))
        end
        available = Builtins.filter(available) { |s| s != nil }
        # cmdline about power saving schemes, %1 is list of schemes,
        CommandLine.Print(
          Builtins.sformat(
            _("Available Profiles: %1"),
            Builtins.mergestring(available, ", ")
          )
        )
        printed = true
      end
      false
    end

    # Handler for command line interface
    # @param [Hash] options map options from the command line
    # @return [Boolean] true if settings have been changed
    def SetHandler(options)
      options = deep_copy(options)
      if Builtins.haskey(options, "profile")
        scheme = Ops.get_string(options, "profile", "")
        scheme_id = nil
        ret = false
        Builtins.foreach(PowerManagement.schemes) do |s|
          if Ops.get(s, "SCHEME_NAME") == scheme
            scheme_id = Ops.get(s, "_scheme_id", "")
          end
        end
        if scheme_id != nil
          Ops.set(PowerManagement.global_settings, "SCHEME", scheme_id)
          ret = true
        elsif scheme != ""
          # error report
          CommandLine.Error(_("Specified profile not found."))
        end
        return ret
      end
      false
    end

    # Handler for command line interface
    # @param [Hash] options map options from the command line
    # @return [Boolean] true if settings have been changed
    def SchemeHandler(options)
      options = deep_copy(options)
      s_add = Builtins.haskey(options, "add")
      s_edit = Builtins.haskey(options, "edit")
      s_delete = Builtins.haskey(options, "delete")
      if !(s_add || s_edit || s_delete)
        # error report
        CommandLine.Error(_("Operation with the profile not specified."))
        return false
      end
      if !Builtins.haskey(options, "name")
        # error report
        CommandLine.Error(_("Profile name not specified."))
        return false
      end
      scheme_name = Ops.get_string(options, "name", "")
      if s_delete
        PowerManagement.schemes = Builtins.filter(PowerManagement.schemes) do |s|
          Ops.get(s, "SCHEME_NAME", "") != scheme_name
        end
        return true
      end

      PowerManagement.FetchSchemes
      if s_add
        original_scheme = scheme_name
        if !Builtins.haskey(options, "clone")
          original_scheme = Ops.get(
            PowerManagement.schemes,
            [0, "SCHEME_NAME"],
            ""
          )
        else
          original_scheme = Ops.get_string(options, "clone", "")
        end
        PowerManagement.FetchScheme(
          -1,
          PowerManagement.FindScheme(original_scheme)
        )
        Ops.set(PowerManagement.current_scheme, "SCHEME_NAME", scheme_name)
      else
        PowerManagement.FetchScheme(
          PowerManagement.FindScheme(scheme_name),
          nil
        )
      end
      if Builtins.haskey(options, "description")
        Ops.set(
          PowerManagement.current_scheme,
          "SCHEME_DESCRIPTION",
          Ops.get_string(options, "description", "")
        )
      end
      if Builtins.haskey(options, "rename")
        Ops.set(
          PowerManagement.current_scheme,
          "SCHEME_NAME",
          Ops.get_string(options, "rename", "")
        )
      end
      if Builtins.haskey(options, "option") && Builtins.haskey(options, "value")
        Ops.set(
          PowerManagement.current_scheme,
          Ops.get_string(options, "option", ""),
          Ops.get_string(options, "value", "")
        )
      end

      PowerManagement.StoreScheme
      PowerManagement.StoreSchemes
      true
    end
  end
end
