# Sources for power-management

module_DATA = \
  modules/PowerManagement.rb

client_DATA = \
  clients/power-management_auto.rb \
  clients/power-management.rb

yncludedir = @yncludedir@/power-management
ynclude_DATA = \
  include/power-management/widgets.rb \
  include/power-management/wizards.rb \
  include/power-management/commandline.rb \
  include/power-management/dialogs.rb \
  include/power-management/helps.rb

scrconf_DATA = \
  scrconf/etc_pm-profiler.scr \
  scrconf/etc_pm-profiler_profiles.scr

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/power-management.rnc

desktop_DATA = \
  desktop/power-management.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(schemafiles_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common