cmake_minimum_required(VERSION 2.6)

include(ReMake)

remake_project(
  ubash-scripts
  VERSION 0.1
  RELEASE beta
  SUMMARY "Script examples for the useful bash environment."
  AUTHOR "Ralf Kaestner"
  CONTACT "ralf.kaestner@gmail.com"
  HOME "http://github.com/kralf/ubash"
  LICENSE "GNU Lesser General Public License (LGPL)"
  INSTALL /usr
)

remake_pack_deb(
  ARCH all
  DEPENDS ubash
)

remake_distribute_deb(
  DISTRIBUTION lucid
  SECTION misc
  UPLOAD ppa:kralf/asl
  DEPENDS ubash remake
  PASS CMAKE_BUILD_TYPE UBASH_SCRIPTS_GIT_REVISION
)
remake_distribute_deb(
  DISTRIBUTION precise
  SECTION misc
  UPLOAD ppa:kralf/asl
  DEPENDS ubash remake
  PASS CMAKE_BUILD_TYPE UBASH_SCRIPTS_GIT_REVISION
)
remake_distribute_deb(
  DISTRIBUTION trusty
  SECTION misc
  UPLOAD ppa:kralf/asl
  DEPENDS ubash remake
  PASS CMAKE_BUILD_TYPE UBASH_SCRIPTS_GIT_REVISION
)
