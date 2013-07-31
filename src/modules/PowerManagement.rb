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
# File:	modules/PowerManagement.ycp
# Package:	Configuration of power-management
# Summary:	PowerManagement settings, input and output functions
# Authors:	Jiri Srain <jsrain@suse.cz>
#
# $Id$
#
# Representation of the configuration of power-management.
# Input and output routines.
require "yast"

module Yast
  class PowerManagementClass < Module
    def main
      textdomain "power-management"

      Yast.import "Mode"
      Yast.import "PackageSystem"
      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Service"
      Yast.import "String"


      # Mapping of cheme option identifiers in the internal structure and in the
      # created file
      # Key is internal structure, value is scheme file
      @scheme_options_mapping =
        #    "" : "",
        {
          "SCHEME_NAME"                     => "NAME",
          "SCHEME_DESCRIPTION"              => "DESCRIPTION",
          "SATA_ALPM"                       => "SATA_ALPM",
          "CPUFREQ_GOVERNOR"                => "CPUFREQ_GOVERNOR",
          "CPUFREQ_SCHED_MC_POWER_SAVINGS"  => "CPUFREQ_SCHED_MC_POWER_SAVINGS",
          "CPUFREQ_ONDEMAND_UP_THRESHOLD"   => "CPUFREQ_ONDEMAND_UP_THRESHOLD",
          "CPUFREQ_ONDEMAND_POWERSAVE_BIAS" => "CPUFREQ_ONDEMAND_POWERSAVE_BIAS"
        }

      # Mapping of global option identifiers in the internal structure and in the
      # created file
      # Key is internal structure, value is scheme file (2-member list, first file
      # identifier, second variable name)
      @global_options_mapping =
        #    ""		: "",
        { "SCHEME" => "PM_PROFILER_PROFILE" }

      # persistent variables

      @schemes = []

      @global_settings = {}

      @new_schemes = {}

      @default_values = {}

      # not needed any more, getting from kpowersave package
      #  global map scheme_names = $[
      #     // power saving scheme name, combo box and default contents of text entry
      #     "Performance" : _("Performance"),
      #     // power saving scheme name, combo box and default contents of text entry
      #     "Powersave" : _("Powersave"),
      #     // power saving scheme name, combo box and default contents of text entry
      #     "Acoustic" : _("Acoustic"),
      #     // power saving scheme name, combo box and default contents of text entry
      #     "Presentation" : _("Presentation"),
      # ];
      #
      # global map scheme_desciptions = $[
      #     "Scheme optimized to let machine run on maximum performance." :
      # 	// pwer saving scheme description, contents of text entry
      # 	_("Scheme optimized to let machine run on maximum performance."),
      #     "Scheme optimized to let maximum power savings take place." :
      # 	// pwer saving scheme description, contents of text entry
      # 	_("Scheme optimized to let maximum power savings take place."),
      #     "Scheme optimized to let machine run as quiet as possible." :
      # 	// pwer saving scheme description, contents of text entry
      # 	_("Scheme optimized to let machine run as quietly as possible."),
      # ];


      # Data was modified?
      @modified = false


      @proposal_valid = false

      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false

      # Abort function
      # return boolean return true if abort
      @AbortFunction = nil

      # UI helping variables

      @current_schemes = []
      @current_scheme_index = -1
      @current_scheme = {}

      @power_available = true
      @sleep_available = true
      @lid_available = true
    end

    # Abort function
    # @return blah blah lahjk
    def Abort
      return @AbortFunction.call if @AbortFunction != nil
      false
    end

    # Data was modified?
    # @return true if modified
    def Modified
      Builtins.y2debug("modified=%1", @modified)
      @modified
    end

    # Read all power-management settings
    # @return true on success
    def Read
      Builtins.y2milestone("Reading power management settings")
      @AbortFunction = nil if Mode.config

      # hide progress, it is too fast (bnc #447574)
      progress_status = Progress.set(false)

      # PowerManagement read dialog caption
      caption = _("Initializing Configuration")

      steps = 3

      sl = 0
      Builtins.sleep(sl)

      success = true
      stage_success = true

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/3
          _("Check the environment"),
          # Progress stage 2/3
          _("Read general settings"),
          # Progress stage 3/3
          _("Read power saving profiles")
        ],
        [
          # Progress step 1/3
          _("Checking the environment..."),
          # Progress step 2/3
          _("Reading general settings..."),
          # Progress step 3/3
          _("Reading power saving profiles..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )

      # read database
      if Abort()
        Progress.set(progress_status)
        return false
      end
      Progress.NextStage

      # check installed packages
      if !Mode.test &&
          !PackageSystem.CheckAndInstallPackagesInteractive(["pm-profiler"])
        Progress.set(progress_status)
        return false
      end

      # stage always successful
      #    if(! stage_success)
      #    {
      #	/* Error message */
      #	Report::Error(_("Cannot read the database."));
      #    }
      success = success && stage_success
      stage_success = true
      Builtins.sleep(sl)

      # read general settings
      if Abort()
        Progress.set(progress_status)
        return false
      end
      Progress.NextStage

      r_schemes = SCR.Dir(path(".etc.pm-profiler.profiles.section"))
      Builtins.foreach(@global_options_mapping) do |key, conf|
        v = Convert.to_string(SCR.Read(Ops.add(path(".etc.pm-profiler"), conf)))
        Ops.set(@global_settings, key, v) if v != nil
      end

      if !stage_success
        # Error message
        Report.Error(_("Cannot read the general settings."))
      end
      success = success && stage_success
      stage_success = true
      Builtins.sleep(sl)

      # read saving schemes
      if Abort()
        Progress.set(progress_status)
        return false
      end
      Progress.NextStage

      @schemes = Builtins.maplist(r_schemes) do |s|
        scheme = { "_scheme_id" => s }
        p = Builtins.add(path(".etc.pm-profiler.profiles.value"), s)
        Builtins.foreach(@scheme_options_mapping) do |key, conf|
          v = Convert.to_string(SCR.Read(Builtins.add(p, conf)))
          Ops.set(scheme, key, v)
        end
        deep_copy(scheme)
      end
      @new_schemes = {}

      if !stage_success
        # Error message
        Report.Warning(_("Cannot read power saving profiles."))
      end
      Builtins.sleep(sl)

      # Progress finished
      Progress.NextStage
      success = success && stage_success
      Builtins.sleep(sl)

      @modified = false

      Builtins.y2debug("Global settings: %1", @global_settings)
      Builtins.y2debug("Power saving schemes: %1", @schemes)

      Progress.set(progress_status)
      success
    end

    # Write all power-management settings
    # @return true on success
    def Write
      Builtins.y2milestone("Writing power management settings")
      @AbortFunction = nil if Mode.autoinst

      # PowerManagement read dialog caption
      caption = _("Saving Configuration")

      steps = 2

      sl = 0
      Builtins.sleep(sl)

      success = true
      stage_success = true

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/3
          #	    _("Write profiles"),
          # Progress stage 2/3
          _("Write general settings"),
          # Progress stage 3/3
          _("Restart pm-profiler daemon")
        ],
        [
          # Progress step 1/3
          #	    _("Writing profiles..."),
          # Progress step 2/3
          _("Writing general settings..."),
          # Progress step 3/3
          _("Restarting pm-profiler daemon..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )

      # write schemes
      return false if Abort()
      Progress.NextStage
      #     y2milestone ("Writing power saving schemes");
      #     // copy new scheme files
      #     foreach (string dst, string src, new_schemes, ``{
      # 	if (dst != "")
      # 	{
      # 	    y2milestone ("Creating config file of scheme %1 as copy of %2",
      # 		dst, src);
      # 	    stage_success = (0 == SCR::Execute (.target.bash, sformat (
      # 		"cat /etc/pm-profiler/%1 >  /etc/pm-profiler/%2",
      # 		src, dst))) && stage_success;
      # 	}
      #     });
      #
      #     // remove deleted schemes
      #     list<string> old = (list<string>)SCR::Dir (.etc.pm-profiler.profiles.section);
      #     list<string> current = maplist (map<string,string> s, schemes, ``(
      # 	s["_scheme_id"]:""
      #     ));
      #     list<string> delete = filter (string s, old, ``(! contains (current, s)));
      #     foreach (string s, delete, ``{
      # 	SCR::Write (add (.etc.pm-profiler.profils.section, s), nil);
      #     });
      #
      #     // write scheme settings
      #     foreach (map<string,string> scheme, schemes, ``{
      # 	string id = scheme["_scheme_id"]:"";
      # 	y2milestone ("Writing scheme %1", id);
      # 	path p = add (.etc.pm-profiler.profiles.value, id);
      # 	foreach (string key, string conf, scheme_options_mapping, {
      # 	    if (key != "_scheme_id")
      # 	    {
      # 		string v = scheme[key]:nil;
      # 		SCR::Write (add (p, conf), v);
      # 	    }
      # 	});
      #     });
      #     SCR::Write (.etc.pm-priofiler.profiles, nil);
      #
      #     if(! stage_success)
      #     {
      # 	// Error message
      # 	Report::Error(_("Cannot write power saving profiles."));
      #     }
      #     success = success && stage_success;
      #     stage_success = true;
      #     sleep(sl);
      #
      #     // write global settings
      #     if(Abort()) return false;
      #     Progress::NextStage ();
      Builtins.y2milestone("Writing global settings")
      @global_settings = Builtins.mapmap(@global_settings) do |k, v|
        v = "" if Ops.get(@default_values, k, "") == v
        { k => v }
      end
      Builtins.foreach(@global_options_mapping) do |key, conf|
        v = Ops.get(@global_settings, key)
        SCR.Write(Ops.add(path(".etc.pm-profiler"), conf), v)
      end
      SCR.Write(path(".etc.pm-profiler"), nil)

      if !stage_success
        # Error message
        Report.Error(_("Cannot write general settings."))
      end
      success = success && stage_success
      stage_success = true
      Builtins.sleep(sl)

      # restart daemon
      return false if Abort()
      Progress.NextStage

      if Ops.get(@global_settings, "SCHEME", "") == ""
        Builtins.y2milestone("Stopping pm-profiler daemon")
        stage_success = Service.Stop("pm-profiler") if !@write_only
        stage_success = Service.Disable("pm-profiler") && stage_success
      else
        Builtins.y2milestone("Restarting pm-profiler daemon")
        stage_success = Service.Restart("pm-profiler") if !@write_only
        stage_success = Service.Enable("pm-profiler") && stage_success
      end

      if !stage_success
        # Error message
        Report.Error(_("Cannot restart the pm-profiler daemon."))
      end
      success = success && stage_success
      stage_success = true
      Builtins.sleep(sl)

      # Progress finished
      Progress.NextStage
      Builtins.sleep(sl)
      Builtins.sleep(500)

      true
    end

    # Get all power-management settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      Builtins.y2milestone("Importing settings: %1", settings)
      @schemes = Ops.get_list(settings, "schemes", [])
      @global_settings = Ops.get_map(settings, "global_settings", {})
      true
    end

    # Dump the power-management settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      ret = { "schemes" => @schemes, "global_settings" => @global_settings }
      Builtins.y2milestone("Exporting settings: %1", ret)
      deep_copy(ret)
    end

    # Create a textual summary and a list of unconfigured cards
    # @return summary of the current configuration
    def Summary
      scheme = Ops.get(@global_settings, "SCHEME", "")
      if scheme == ""
        scheme = _("Default settings")
      else
        Builtins.foreach(@schemes) do |s|
          if Ops.get(s, "_scheme_id", "") == scheme
            scheme = Ops.get(s, "SCHEME_DESCRIPTION", "")
          end
        end
      end

      ret = [
        # summary text, %1 is scheme name
        Builtins.sformat(_("Selected Profile: %1"), scheme)
      ]
      Builtins.y2milestone("Power management summary: %1", ret)

      deep_copy(ret)
    end

    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      { "install" => ["pm-profiler"], "remove" => [] }
    end

    # Translate a text using powersave mo-file
    # @param [String] text string to translate
    # @return [String] translated text
    def TranslatePowersaveText(text)
      return text if text == ""
      out = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          Builtins.sformat(
            "TEXTDOMAINDIR=/usr/share/locale/ gettext pm-profiler \"%1\"",
            text
          )
        )
      )
      return text if Ops.get_integer(out, "exit", -1) != 0
      translated = Ops.get_string(out, "stdout", "")
      translated
    end

    # Get localized scheme name
    # @param [String] name string original scheme name
    # @return [String] localized scheme name
    def TranslateSchemeName(name)
      TranslatePowersaveText(name)
    end

    # Get localized scheme description
    # @param [String] descr string original scheme desceriptino
    # @return [String] localized scheme decription
    def TranslateSchemeDescription(descr)
      TranslatePowersaveText(descr)
    end

    # Find index of a scheme
    # @param [String] name string scheme name
    # @return [Fixnum] scheme index (-1 if not found)
    def FindScheme(name)
      ret = -1
      index = -1
      Builtins.foreach(@schemes) do |s|
        index = Ops.add(index, 1)
        ret = index if Ops.get(s, "SCHEME_NAME", "") == name
      end
      ret
    end

    # Fetch all schemes
    def FetchSchemes
      @current_schemes = deep_copy(@schemes)

      nil
    end

    # Store all schemes
    def StoreSchemes
      @schemes = deep_copy(@current_schemes)
      @modified = true

      nil
    end

    # fetch a scheme
    # @param [Fixnum] index integer index of the scheme (-1 is new scheme)
    # @param [Fixnum] clone integer index of scheme to clone if not exists
    def FetchScheme(index, clone)
      @current_scheme_index = index
      if index == -1
        if clone != nil
          @current_scheme = Ops.get(@current_schemes, clone, {})
        else
          @current_scheme = Ops.get(@current_schemes, 0, {})
        end
      else
        @current_scheme = Ops.get(@current_schemes, index, {})
      end
      if @current_scheme == {}
        @current_scheme = Ops.get(@current_schemes, 0, {})
      end

      nil
    end

    # Store the current scheme
    def StoreScheme
      if @current_scheme_index == -1
        @current_schemes = Builtins.add(@current_schemes, @current_scheme)
      else
        Ops.set(@current_schemes, @current_scheme_index, @current_scheme)
      end

      nil
    end

    publish :function => :Modified, :type => "boolean ()"
    publish :variable => :schemes, :type => "list <map <string, string>>"
    publish :variable => :global_settings, :type => "map <string, string>"
    publish :variable => :new_schemes, :type => "map <string, string>"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :write_only, :type => "boolean"
    publish :variable => :AbortFunction, :type => "boolean ()"
    publish :variable => :current_schemes, :type => "list <map <string, string>>"
    publish :variable => :current_scheme_index, :type => "integer"
    publish :variable => :current_scheme, :type => "map <string, string>"
    publish :variable => :power_available, :type => "boolean"
    publish :variable => :sleep_available, :type => "boolean"
    publish :variable => :lid_available, :type => "boolean"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "list <string> ()"
    publish :function => :AutoPackages, :type => "map ()"
    publish :function => :TranslatePowersaveText, :type => "string (string)"
    publish :function => :TranslateSchemeName, :type => "string (string)"
    publish :function => :TranslateSchemeDescription, :type => "string (string)"
    publish :function => :FindScheme, :type => "integer (string)"
    publish :function => :FetchSchemes, :type => "void ()"
    publish :function => :StoreSchemes, :type => "void ()"
    publish :function => :FetchScheme, :type => "void (integer, integer)"
    publish :function => :StoreScheme, :type => "void ()"
  end

  PowerManagement = PowerManagementClass.new
  PowerManagement.main
end
