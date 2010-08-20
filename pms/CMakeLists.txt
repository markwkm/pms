CMAKE_MINIMUM_REQUIRED(VERSION 2.4)
PROJECT(PMS)

#
# Install rules.
#

INSTALL(PROGRAMS
        bin/pms-build-tree
        DESTINATION "/bin")
