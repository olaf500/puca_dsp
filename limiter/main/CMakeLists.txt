set(SOURCES main.cpp WM8978.cpp picodsp_mics_omninew.cpp)
idf_component_register(SRCS ${SOURCES}
                    INCLUDE_DIRS "")
