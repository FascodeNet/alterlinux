add_library(lxdialog checklist.c inputbox.c menubox.c textbox.c util.c yesno.c)
target_link_libraries(lxdialog ${CURSES_LIBRARIES})
