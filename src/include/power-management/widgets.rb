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
# File:	include/power-management/complex.ycp
# Package:	Configuration of power-management
# Summary:	Dialogs definitions
# Authors:	Jiri Srain <jsrain@suse.cz>
#
# $Id$
module Yast
  module PowerManagementWidgetsInclude
    def initialize_power_management_widgets(include_target)
      Yast.import "UI"

      textdomain "power-management"

      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "PowerManagement"
      Yast.import "String"

      Yast.include include_target, "power-management/helps.rb"

      # scheme name widget

      @original_scheme_name = ""
      @widget_init_scheme_name = ""

      # scheme description widget

      @widget_init_scheme_descr = ""

      # general settings

      @widgets = {
        "scheme_selection" => getSchemeSelectionWidget,
        "schemes_list"     => getSchemesListWidget,
        "scheme_name"      => getSchemeNameWidget,
        "scheme_descr"     => getSchemeDescrWidget,
        "hard_disk"        => getHardDiskWidget,
        "cpu"              => getCpuWidget
      } 

      # EOF
    end

    # scheme selection widget

    # Handle function of a widget
    # @param [String] key string widget id
    # @param [Hash] event map event that will be handled
    # @return [Symbol] for wizard sequencer
    def SchemeSelectionHandle(key, event)
      event = deep_copy(event)
      ev_id = Ops.get(event, "ID")
      return :schemes_edit if ev_id == :schemes_edit
      if ev_id == :scheme
        current = Convert.to_string(UI.QueryWidget(Id(ev_id), :Value))
        if current == ""
          UI.ChangeWidget(Id(:descr), :Value, _("Default system settings"))
          return nil
        end
        descr = ""
        Builtins.foreach(PowerManagement.schemes) do |s|
          if Ops.get_string(s, "_scheme_id", "") == current
            descr = Ops.get_string(s, "SCHEME_DESCRIPTION", "")
          end
        end
        descr = PowerManagement.TranslateSchemeDescription(descr)
        if descr == ""
          # fallback scheme description, displayed in a rich text
          # but without HTML tags!!!
          descr = _("No profile description available")
        end
        UI.ChangeWidget(Id(:descr), :Value, descr)
      end

      nil
    end

    # Init function of a widget
    # @param [String] key string widget id
    def SchemeSelectionInit(key)
      items = Builtins.maplist(PowerManagement.schemes) do |s|
        id = Ops.get(s, "_scheme_id", "")
        name = Ops.get(s, "SCHEME_NAME", id)
        name = PowerManagement.TranslateSchemeName(name)
        Item(Id(id), name)
      end
      items = Builtins.add(items, Item(Id(""), _("Default")))

      UI.ReplaceWidget(
        :scheme_rp,
        ComboBox(
          Id(:scheme),
          Opt(:hstretch, :notify),
          # combo box
          _("&Selected Profile"),
          items
        )
      )
      scheme = Ops.get(PowerManagement.global_settings, "SCHEME", "")
      UI.ChangeWidget(Id(:scheme), :Value, scheme)
      SchemeSelectionHandle(key, { "ID" => :scheme })

      nil
    end

    # Store settings of a widget
    # @param [String] key string widget id
    # @param [Hash] event map event that caused storing of widget settings
    def SchemeSelectionStore(key, event)
      event = deep_copy(event)
      Ops.set(
        PowerManagement.global_settings,
        "SCHEME",
        Convert.to_string(UI.QueryWidget(Id(:scheme), :Value))
      )

      nil
    end

    # Get description map of a widget
    # @return a map widget description map
    def getSchemeSelectionWidget
      {
        "widget"        => :custom,
        # frame
        "custom_widget" => Frame(
          _("Energy Saving Profiles"),
          VBox(
            HBox(
              HWeight(
                1,
                VBox(
                  ReplacePoint(
                    Id(:scheme_rp),
                    ComboBox(
                      Id(:scheme),
                      Opt(:hstretch, :notify),
                      # combo box
                      _("&AC Powered"),
                      []
                    )
                  ),
                  RichText(Id(:descr), Opt(:hstretch), "")
                )
              ) # 	    ),
              # 	    `HBox (
              # 		`HStretch (),
              # 		`PushButton (`id (`schemes_edit),
              # 		    // push button
              # 		    _("Ed&it Profiles")),
              # 		`HStretch ()
            )
          )
        ),
        "init"          => fun_ref(
          method(:SchemeSelectionInit),
          "void (string)"
        ),
        "handle"        => fun_ref(
          method(:SchemeSelectionHandle),
          "symbol (string, map)"
        ),
        "handle_events" => [:schemes_edit, :scheme, :dc_scheme],
        "store"         => fun_ref(
          method(:SchemeSelectionStore),
          "void (string, map)"
        ),
        "help"          => Ops.get_string(@HELPS, "scheme_selection", "")
      }
    end


    # schemes list widget

    # Redraw the table of energy saving schemes
    def SchemesRedraw
      items = Builtins.maplist(PowerManagement.current_schemes) do |s|
        scheme_id = Ops.get(s, "_scheme_id", "")
        name = Ops.get(s, "SCHEME_NAME", scheme_id)
        name = PowerManagement.TranslateSchemeName(name)
        descr = Ops.get(s, "SCHEME_DESCRIPTION", "")
        descr = PowerManagement.TranslateSchemeDescription(descr)
        if descr == ""
          # fallback scheme description, table entre
          descr = _("No profile description available")
        end
        Item(Id(scheme_id), name, descr)
      end
      UI.ChangeWidget(Id(:schemes), :Items, items)
      UI.SetFocus(:schemes)

      nil
    end

    # Handle function of a widget
    # @param [String] key string widget id
    # @param [Hash] event map event that will be handled
    # @return [Symbol] for wizard sequencer
    def SchemesHandle(key, event)
      event = deep_copy(event)
      event_id = Ops.get(event, "ID")
      selected = Convert.to_string(UI.QueryWidget(Id(:schemes), :CurrentItem))
      index = -1
      found = -1
      Builtins.foreach(PowerManagement.current_schemes) do |s|
        index = Ops.add(index, 1)
        if Ops.get(PowerManagement.current_schemes, [index, "_scheme_id"], "") == selected
          found = index
        end
      end
      if event_id == :add
        PowerManagement.current_scheme_index = -1
        PowerManagement.current_scheme = Ops.get(
          PowerManagement.current_schemes,
          found,
          {}
        )
        Ops.set(PowerManagement.current_scheme, "_scheme_id", "")
        Ops.set(PowerManagement.current_scheme, "SCHEME_NAME", "")
        Ops.set(PowerManagement.new_schemes, "", selected)
        return :add
      elsif event_id == :edit
        if selected == nil
          # popup message
          Popup.Message(_("No profile selected."))
        end
        if selected == "performance" || selected == "powersave"
          # FIXME update after talking to MD people
          if false
            # popup message
            Popup.Message(
              _(
                "The selected profile cannot be modified.\nAdd a new one instead."
              )
            )
            return nil
          end
        end
        PowerManagement.current_scheme_index = found
        PowerManagement.current_scheme = Ops.get(
          PowerManagement.current_schemes,
          found,
          {}
        )
        return :edit
      elsif event_id == :delete
        if selected == nil
          # popup message
          Popup.Message(_("No profile selected."))
        end
        PowerManagement.current_schemes = Builtins.filter(
          PowerManagement.current_schemes
        ) do |s|
          Ops.get(s, "_scheme_id", "") != selected
        end
        SchemesRedraw()
        UI.ChangeWidget(
          Id(:schemes),
          :CurrentItem,
          Ops.get(PowerManagement.current_schemes, [0, "_scheme_id"], "")
        )
        if Builtins.haskey(PowerManagement.new_schemes, selected)
          PowerManagement.new_schemes = Builtins.remove(
            PowerManagement.new_schemes,
            selected
          )
        end
      end
      selected = Convert.to_string(UI.QueryWidget(Id(:schemes), :CurrentItem))
      enabled = true
      enabled = false if selected == "performance" || selected == "powersave"
      UI.ChangeWidget(Id(:delete), :Enabled, enabled)
      nil
    end

    # Init function of a widget
    # @param [String] key string widget id
    def SchemesInit(key)
      SchemesRedraw()
      SchemesHandle(key, {})
      UI.ChangeWidget(
        Id(:schemes),
        :CurrentItem,
        Ops.get(PowerManagement.current_schemes, [0, "_scheme_id"], "")
      )

      nil
    end

    # Get description map of a widget
    # @return a map widget description map
    def getSchemesListWidget
      {
        "widget"        => :custom,
        "custom_widget" => VBox(
          Table(
            Id(:schemes),
            Opt(:notify, :immediate),
            Header(
              # table header
              _("Profile Name"),
              # table header
              _("Profile Description")
            ),
            []
          ),
          HBox(
            PushButton(Id(:add), Label.AddButton),
            PushButton(Id(:edit), Label.EditButton),
            PushButton(Id(:delete), Label.DeleteButton),
            HStretch()
          )
        ),
        "init"          => fun_ref(method(:SchemesInit), "void (string)"),
        "handle"        => fun_ref(
          method(:SchemesHandle),
          "symbol (string, map)"
        ),
        "help"          => Ops.get_string(@HELPS, "schemes_list", "")
      }
    end

    # Init function of a widget
    # @param [String] key string widget id
    def SchemeNameInit(key)
      scheme_name = Ops.get(PowerManagement.current_scheme, "SCHEME_NAME", "")
      if scheme_name == ""
        scheme_name = Ops.get(PowerManagement.current_scheme, "_scheme_id", "")
      end
      scheme_name = PowerManagement.TranslateSchemeName(scheme_name)
      @original_scheme_name = Ops.get(
        PowerManagement.current_schemes,
        [PowerManagement.current_scheme_index, "SCHEME_NAME"],
        ""
      )
      UI.ChangeWidget(Id(key), :Value, scheme_name)
      @widget_init_scheme_name = scheme_name

      nil
    end

    # Validate function of a widget
    # @param [String] key string widget id
    # @param [Hash] event map event that caused widget validation
    # @return [Boolean] true if validation succeeded
    def SchemeNameValidate(key, event)
      event = deep_copy(event)
      new_name = Convert.to_string(UI.QueryWidget(Id(key), :Value))
      if new_name == ""
        # popup message
        Popup.Message(_("Profile name must be set."))
        return false
      end
      return true if new_name == @original_scheme_name
      names = Builtins.maplist(PowerManagement.current_schemes) do |s|
        Ops.get_string(s, "SCHEME_NAME", Ops.get_string(s, "_scheme_key", ""))
      end
      if Builtins.contains(names, new_name)
        # popup message
        Popup.Message(_("The specified profile name is not unique."))
        return false
      end
      if Ops.greater_than(Builtins.size(new_name), 32)
        Popup.Message(
          # pop-up message
          _("The profile name must not be longer than 32 characters.")
        )
        return false
      end
      true
    end

    # Store settings of a widget
    # @param [String] key string widget id
    # @param [Hash] event map event that caused storing of widget settings
    def SchemeNameStore(key, event)
      event = deep_copy(event)
      new_name = Convert.to_string(UI.QueryWidget(Id(key), :Value))
      if new_name != @widget_init_scheme_name
        Ops.set(PowerManagement.current_scheme, "SCHEME_NAME", new_name)
      end

      if @original_scheme_name == ""
        scheme_id = new_name
        # allow only ASCII characters + numbers in the file name
        scheme_id = Builtins.filterchars(scheme_id, String.CAlnum)
        scheme_id = "user" if scheme_id == ""
        ids = Builtins.maplist(PowerManagement.current_schemes) do |s|
          Ops.get_string(s, "_scheme_id", "")
        end
        if Builtins.contains(ids, scheme_id)
          index = 0
          while Builtins.contains(
              ids,
              Builtins.sformat("%1_%2", scheme_id, index)
            )
            index = Ops.add(index, 1)
          end
          scheme_id = Builtins.sformat("%1_%2", scheme_id, index)
        end
        Ops.set(PowerManagement.current_scheme, "_scheme_id", scheme_id)

        Ops.set(
          PowerManagement.new_schemes,
          scheme_id,
          Ops.get(PowerManagement.new_schemes, "", "")
        )
      end

      nil
    end

    # Get description map of a widget
    # @return a map widget description map
    def getSchemeNameWidget
      {
        "widget"            => :textentry,
        # text entry
        "label"             => _("S&cheme Name"),
        "help"              => Ops.get_string(@HELPS, "scheme_name", ""),
        "init"              => fun_ref(method(:SchemeNameInit), "void (string)"),
        "store"             => fun_ref(
          method(:SchemeNameStore),
          "void (string, map)"
        ),
        "validate_type"     => :function,
        "validate_function" => fun_ref(
          method(:SchemeNameValidate),
          "boolean (string, map)"
        )
      }
    end

    # Init function of a widget
    # @param [String] key string widget id
    def SchemeDescrInit(key)
      descr = Ops.get(PowerManagement.current_scheme, "SCHEME_DESCRIPTION", "")
      descr = PowerManagement.TranslateSchemeDescription(descr)
      UI.ChangeWidget(Id(key), :Value, descr)
      @widget_init_scheme_descr = descr

      nil
    end

    # Store settings of a widget
    # @param [String] key string widget id
    # @param [Hash] event map event that caused storing of widget settings
    def SchemeDescrStore(key, event)
      event = deep_copy(event)
      descr = Convert.to_string(UI.QueryWidget(Id(key), :Value))
      if @widget_init_scheme_descr != descr
        Ops.set(PowerManagement.current_scheme, "SCHEME_DESCRIPTION", descr)
      end

      nil
    end

    # Get description map of a widget
    # @return a map widget description map
    def getSchemeDescrWidget
      {
        "widget" => :textentry,
        # text entry
        "label"  => _("Profile &Description"),
        "help"   => Ops.get_string(@HELPS, "scheme_descr", ""),
        "init"   => fun_ref(method(:SchemeDescrInit), "void (string)"),
        "store"  => fun_ref(method(:SchemeDescrStore), "void (string, map)")
      }
    end

    # hard disk settings widget

    # Init function of a widget
    # @param [String] key string widget id
    def HardDiskInit(key)
      value = Ops.get(PowerManagement.current_scheme, "SATA_ALPM", "")
      value = "max_performance" if value == ""
      UI.ChangeWidget(Id(:alpm), :Value, value)

      nil
    end

    # Store settings of a widget
    # @param [String] key string widget id
    # @param [Hash] event map event that caused storing of widget settings
    def HardDiskStore(key, event)
      event = deep_copy(event)
      Ops.set(
        PowerManagement.current_scheme,
        "SATA_ALPM",
        Convert.to_string(UI.QueryWidget(Id(:alpm), :Value))
      )

      nil
    end

    # Get description map of a widget
    # @return a map widget description map
    def getHardDiskWidget
      {
        "widget"        => :custom,
        # frame,
        "custom_widget" => Frame(
          _("SATA Power Management"),
          HBox(
            HStretch(),
            VBox(
              VStretch(),
              # combo box
              Left(
                ComboBox(
                  Id(:alpm),
                  Opt(:hstretch),
                  # combo box
                  _("Aggressive Link Power Management"),
                  [
                    Item(
                      Id("min_power"),
                      # combo box item
                      _("Maximum Power Saving")
                    ),
                    Item(
                      Id("medium_power"),
                      # combo box item
                      _("Medium Power Saving")
                    ),
                    Item(
                      Id("max_performance"),
                      # combo box item
                      _("Maximum Performance")
                    )
                  ]
                )
              ),
              VStretch()
            ),
            HStretch()
          )
        ),
        "init"          => fun_ref(method(:HardDiskInit), "void (string)"),
        "store"         => fun_ref(method(:HardDiskStore), "void (string, map)"),
        "help"          => Ops.get_string(@HELPS, "hard_disk", "")
      }
    end

    # cpu policy widget

    # Handle function of a widget
    # @param [String] key string widget id
    # @param [Hash] event map event that will be handled
    # @return [Symbol] for wizard sequencer
    def CpuHandle(key, event)
      event = deep_copy(event)
      governor = Convert.to_string(UI.QueryWidget(Id(:governor), :Value))
      UI.ChangeWidget(Id(:ondemand_threshold), :Enabled, governor == "ondemand")
      nil
    end

    # Init function of a widget
    # @param [String] key string widget id
    def CpuInit(key)
      Builtins.y2internal("CS: %1", PowerManagement.current_scheme)
      UI.ChangeWidget(
        Id(:governor),
        :Value,
        Ops.get(
          PowerManagement.current_scheme,
          "CPUFREQ_GOVERNOR",
          "performance"
        )
      )
      UI.ChangeWidget(
        Id(:sched_saving),
        :Value,
        Ops.get(
          PowerManagement.current_scheme,
          "CPUFREQ_SCHED_MC_POWER_SAVINGS",
          "0"
        ) == "1"
      )
      UI.ChangeWidget(
        Id(:ondemand_threshold),
        :Value,
        Builtins.tointeger(
          Ops.get(
            PowerManagement.current_scheme,
            "CPUFREQ_ONDEMAND_UP_THRESHOLD",
            "0"
          )
        )
      )
      UI.ChangeWidget(
        Id(:powersave_bias),
        :Value,
        Ops.divide(
          Builtins.tointeger(
            Ops.get(
              PowerManagement.current_scheme,
              "CPUFREQ_ONDEMAND_POWERSAVE_BIAS",
              "1000"
            )
          ),
          10
        )
      )
      CpuHandle(key, nil)

      nil
    end

    # Store settings of a widget
    # @param [String] key string widget id
    # @param [Hash] event map event that caused storing of widget settings
    def CpuStore(key, event)
      event = deep_copy(event)
      Ops.set(
        PowerManagement.current_scheme,
        "CPUFREQ_GOVERNOR",
        Convert.to_string(UI.QueryWidget(Id(:governor), :Value))
      )
      Ops.set(
        PowerManagement.current_scheme,
        "CPUFREQ_SCHED_MC_POWER_SAVINGS",
        Convert.to_boolean(UI.QueryWidget(Id(:sched_saving), :Value)) ? "1" : "0"
      )
      Ops.set(
        PowerManagement.current_scheme,
        "CPUFREQ_ONDEMAND_UP_THRESHOLD",
        Builtins.tostring(
          Convert.to_integer(UI.QueryWidget(Id(:ondemand_threshold), :Value))
        )
      )
      Ops.set(
        PowerManagement.current_scheme,
        "CPUFREQ_ONDEMAND_POWERSAVE_BIAS",
        Builtins.tostring(
          Ops.multiply(
            Convert.to_integer(UI.QueryWidget(Id(:powersave_bias), :Value)),
            10
          )
        )
      )

      nil
    end


    def getCpuWidget
      {
        "widget"        => :custom,
        # frame,
        "custom_widget" => Frame(
          _("CPU Power Management"),
          HBox(
            HStretch(),
            VBox(
              VStretch(),
              # combo box
              Left(
                ComboBox(
                  Id(:governor),
                  Opt(:hstretch, :notify),
                  # combo box
                  _("CPU Frequency Governor"),
                  [
                    Item(
                      Id("powersave"),
                      # combo box item
                      _("Maximum Power Saving")
                    ),
                    Item(
                      Id("performance"),
                      # combo box item
                      _("Maximum Performance")
                    ),
                    Item(
                      Id("ondemand"),
                      # combo box item
                      _("On Demand")
                    ),
                    Item(
                      Id("userspace"),
                      # combo box item
                      _("User Space")
                    )
                  ]
                )
              ),
              VStretch(),
              Left(
                IntField(
                  Id(:ondemand_threshold),
                  _("Load Checking Interval"),
                  0,
                  1000000,
                  0
                )
              ),
              VStretch(),
              Left(
                IntField(
                  Id(:powersave_bias),
                  _("Lower Frequency by (percent)"),
                  0,
                  100,
                  0
                )
              ),
              VStretch(),
              Left(
                CheckBox(Id(:sched_saving), _("Balance Load between CPU Cores"))
              )
            ),
            HStretch()
          )
        ),
        "init"          => fun_ref(method(:CpuInit), "void (string)"),
        "store"         => fun_ref(method(:CpuStore), "void (string, map)"),
        "handle"        => fun_ref(method(:CpuHandle), "symbol (string, map)"),
        "handle_events" => [:governor],
        "help"          => Ops.get_string(@HELPS, "cpu", "")
      }
    end
  end
end
