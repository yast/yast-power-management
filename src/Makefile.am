# Makefile.am for power-management/src

yncludedir = @yncludedir@/power-management
rncdir =  $(schemadir)/autoyast/rnc

rnc_DATA = power-management.rnc

client_DATA =			\
	power-management.ycp		\
	power-management_auto.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	widgets.ycp		\
	commandline.ycp	

desktop_DATA =			\
	power-management.desktop

module_DATA =			\
	PowerManagement.ycp

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA) $(rnc_DATA)

include $(top_srcdir)/Makefile.am.common
