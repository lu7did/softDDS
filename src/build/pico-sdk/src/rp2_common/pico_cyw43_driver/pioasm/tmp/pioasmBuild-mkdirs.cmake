# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/Users/PCOLLA/Documents/GitHub/pico/pico-sdk/tools/pioasm"
  "/Users/PCOLLA/Documents/GitHub/softDDS/src/build/pioasm"
  "/Users/PCOLLA/Documents/GitHub/softDDS/src/build/pioasm-install"
  "/Users/PCOLLA/Documents/GitHub/softDDS/src/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/tmp"
  "/Users/PCOLLA/Documents/GitHub/softDDS/src/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/src/pioasmBuild-stamp"
  "/Users/PCOLLA/Documents/GitHub/softDDS/src/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/src"
  "/Users/PCOLLA/Documents/GitHub/softDDS/src/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/src/pioasmBuild-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/Users/PCOLLA/Documents/GitHub/softDDS/src/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/src/pioasmBuild-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/Users/PCOLLA/Documents/GitHub/softDDS/src/build/pico-sdk/src/rp2_common/pico_cyw43_driver/pioasm/src/pioasmBuild-stamp${cfgdir}") # cfgdir has leading slash
endif()
