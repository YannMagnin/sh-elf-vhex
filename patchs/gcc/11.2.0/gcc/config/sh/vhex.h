#undef STARTFILE_SPEC
#define STARTFILE_SPEC \
  ""

#undef ENDFILE_SPEC
#define ENDFILE_SPEC \
  ""

#undef LIB_SPEC
#define LIB_SPEC "-lc"

#undef USER_LABEL_PREFIX
#define USER_LABEL_PREFIX "_"

#undef LINK_SPEC
#define LINK_SPEC SH_LINK_SPEC "%{shared:-shared} %{static:-static} %{!shared: %{!static: %{rdynamic:-export-dynamic}}}"
