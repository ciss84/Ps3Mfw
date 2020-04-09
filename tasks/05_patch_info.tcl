#!/usr/bin/tclsh
#
# ps3mfw -- PS3 MFW creator
#
# Copyright (C) Anonymous Developers (Code Monkeys)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#

# Priority: 40
# Description: REX2DREX: Patch REBUG 3.55.4 / 4.21.2 REX to D-REX


# Option --spoof: Set DEBUG Firmware version

# Type --spoof: combobox { {99.99 99999 DEX} }

namespace eval 05_patch_info {

    array set ::05_patch_info::options {
	
		--spoof "99.99 99999 DEX"
   }

    proc main {} {
        variable options
		debug "Patching [file tail $::CUSTOM_UPDATE_FLAGS_TXT]"
		set fd [open $::CUSTOM_UPDATE_FLAGS_TXT w]
		puts -nonewline $fd "0100"
		close $fd

		set cex [file join dev_flash vsh module sysconf_plugin.sprx]
			::modify_devflash_file $cex ::05_patch_info::cex_rename
		set cex2 [file join dev_flash vsh module software_update_plugin.sprx]
			::modify_devflash_file $cex2 ::05_patch_info::cex_rename
		set dex [file join dev_flash vsh module software_update_plugin.sprx.dex]
			::modify_devflash_file $dex ::05_patch_info::dex_rename1
		set dex2 [file join dev_flash vsh module sysconf_plugin.sprx.dex]
			::modify_devflash_file $dex2 ::05_patch_info::dex_rename2

		foreach pkg [lsort [glob -nocomplain [file join ${::CUSTOM_UPDATE_DIR} dev_flash_*]]] {
			set unpkgdir [file join ${::CUSTOM_UPDATE_DIR} ${pkg}.unpkg]
				::unpkg_archive $pkg $unpkgdir
			foreach info0 [lsort [glob -nocomplain [file join $unpkgdir info0]]] {
				set search		"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
				set replace		"\xA0\x00\x00\x00"
				set offset 4
				set mask 0				
					catch_die {::patch_elf $info0 $search $offset $replace $mask} \
						"Unable to patch file [file tail $info0]"
			}
			if {[file exists [file join ${::ORIGINAL_SPKG_TAR}]]} {
				file delete -force $pkg
				::pkg_spkg_archive $unpkgdir $pkg
				::copy_spkg
			} else {
				file delete -force $pkg
				::pkg_archive $unpkgdir $pkg
			}
			file delete -force $unpkgdir
				::unpkg_archive $pkg ${::CUSTOM_DEVFLASH_DIR}
		}

		set cos [file join ${::CUSTOM_UPDATE_DIR} CORE_OS_PACKAGE.pkg]
		set cosdir [file join ${::CUSTOM_UPDATE_DIR} CORE_OS_PACKAGE.unpkg]
			::unpkg_archive $cos $cosdir
		set info0 [file join $cosdir info0]
		set search		"\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
		set replace		"\xA0\x00\x00\x00"
		set offset 4
		set mask 0				
			catch_die {::patch_elf $info0 $search $offset $replace $mask} \
				"Unable to patch file [file tail $info0]"

		set cosunpkgdir [file join ${::CUSTOM_UPDATE_DIR} CORE_OS_PACKAGE]
			::cosunpkg_package [file join $cosdir content] $cosunpkgdir
		file rename -force [file join $cosunpkgdir lv2_kernel.self] [file join $cosunpkgdir lv2Ckernel.self]
		file rename -force [file join $cosunpkgdir lv2Dkernel.self] [file join $cosunpkgdir lv2_kernel.self]
		set txt [file join $cosunpkgdir list.txt]
		if {[file exists [file join $txt]]} {
			if {${::NEWMFW_VER} < ${::OFW_2NDGEN_BASE}} {
				set search		"\x44\x6B\x65\x72\x6E\x65\x6C\x2E\x73\x65\x6C\x66\x0A\x6C\x76\x32\x6C\x64\x72\x0A\x6C\x76\x32\x5F"
				set replace		"\x5F\x6B\x65\x72\x6E\x65\x6C\x2E\x73\x65\x6C\x66\x0A\x6C\x76\x32\x6C\x64\x72\x0A\x6C\x76\x32\x43"
				set offset 0
				set mask 0				
					catch_die {::patch_elf $txt $search $offset $replace $mask} \
						"Unable to patch file [file tail $txt]"
			} else {
				set search		"\x44\x6B\x65\x72\x6E\x65\x6C\x2E\x73\x65\x6C\x66\x0A\x6C\x76\x32\x5F"
				set replace		"\x5F\x6B\x65\x72\x6E\x65\x6C\x2E\x73\x65\x6C\x66\x0A\x6C\x76\x32\x43"
				set offset 0
				set mask 0				
					catch_die {::patch_elf $txt $search $offset $replace $mask} \
						"Unable to patch file [file tail $txt]"
			}
		}
			::cospkg_package $cosunpkgdir [file join $cosdir content]
		file delete -force $cosunpkgdir
		if {[file exists [file join ${::ORIGINAL_SPKG_TAR}]]} {
			file delete -force $cos
			::pkg_spkg_archive $cosdir $cos
			::copy_spkg
		} else {
			file delete -force $cos
			::pkg_archive $cosdir $cos
		}
		file delete -force $cosdir

		if {${::NEWMFW_VER} > "4.00"} {
			set df3 [glob -nocomplain [file join ${::CUSTOM_UPDATE_DIR} dev_flash3*]]
			set df3dir [file join ${::CUSTOM_UPDATE_DIR} ${df3}.unpkg]
				::unpkg_archive $df3 $df3dir
			set info0 [file join $df3dir info0]
			if {${::NEWMFW_VER} >= "4.21"} {
				set search		"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
			} else {
				set search		"\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
			}
			set replace		"\xA0\x00\x00\x00"
			set offset 4
			set mask 0				
				catch_die {::patch_elf $info0 $search $offset $replace $mask} \
					"Unable to patch file [file tail $info0]"
			if {[file exists [file join ${::ORIGINAL_SPKG_TAR}]]} {
				file delete -force $df3
				::pkg_spkg_archive $df3dir $df3
				::copy_spkg
			} else {
				file delete -force $df3
				::pkg_archive $df3dir $df3
			}
			file delete -force $df3dir

			set bt [file join ${::CUSTOM_UPDATE_DIR} BLUETOOTH_FIRMWARE.pkg]
			set btdir [file join ${::CUSTOM_UPDATE_DIR} BLUETOOTH_FIRMWARE.unpkg]
				::unpkg_archive $bt $btdir
			set info0 [file join $btdir info0]
			set search		"\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
			set replace		"\xA0\x00\x00\x00"
			set offset 4
			set mask 0				
				catch_die {::patch_elf $info0 $search $offset $replace $mask} \
					"Unable to patch file [file tail $info0]"
			if {[file exists [file join ${::ORIGINAL_SPKG_TAR}]]} {
				file delete -force $bt
				::pkg_spkg_archive $btdir $bt
				::copy_spkg
			} else {
				file delete -force $bt
				::pkg_archive $btdir $bt
			}
			file delete -force $btdir

			set multi [file join ${::CUSTOM_UPDATE_DIR} MULTI_CARD_FIRMWARE.pkg]
			set mdir [file join ${::CUSTOM_UPDATE_DIR} MULTI_CARD_FIRMWARE.unpkg]
				::unpkg_archive $multi $mdir
			set info0 [file join $mdir info0]
			set search		"\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
			set replace		"\xA0\x00\x00\x00"
			set offset 4
			set mask 0				
				catch_die {::patch_elf $info0 $search $offset $replace $mask} \
					"Unable to patch file [file tail $info0]"
			if {[file exists [file join ${::ORIGINAL_SPKG_TAR}]]} {
				file delete -force $multi
				::pkg_spkg_archive $mdir $multi
				::copy_spkg
			} else {
				file delete -force $multi
				::pkg_archive $mdir $multi
			}
			file delete -force $mdir
		}

		set release [lindex $options(--spoof) 0]
		set build [lindex $options(--spoof) 1]
		set target [lindex $options(--spoof) 2]
		set auth [lindex $options(--spoof) 1]
		set bdate [lindex $options(--spoof) 3]
		if {$build != ""} {
			log "Patching UPL.xml"
			::modify_upl_file ::05_patch_info::upl_xml
		}

		if {${::NEWMFW_VER} >= "4.21"} {
			set upl [file join ${::CUSTOM_UPDATE_DIR} UPL.xml.pkg]
			set upldir [file join ${::CUSTOM_UPDATE_DIR} UPL.xml.unpkg]
				::unpkg_archive $upl $upldir
			set info0 [file join $upldir info0]
			set search		"\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00"
			set replace		"\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x20"
			set offset 0
			set mask 0				
				catch_die {::patch_elf $info0 $search $offset $replace $mask} \
					"Unable to patch file [file tail $info0]"
			if {[file exists [file join ${::ORIGINAL_SPKG_TAR}]]} {
				file delete -force $upl
				::pkg_spkg_archive $upldir $upl
				::copy_spkg
			} else {
				file delete -force $upl
				::pkg_archive $upldir $upl
			}
			file delete -force $upldir
		}
	}

    proc cex_rename {self} {
		file rename -force $self $self.cex
	}
    proc dex_rename1 {self} {
		set dst [file join ${::CUSTOM_DEV2_DIR} vsh module software_update_plugin.sprx]
		file rename -force $self $dst
	}
    proc dex_rename2 {self} {
		set dst [file join ${::CUSTOM_DEV2_DIR} vsh module sysconf_plugin.sprx]
		file rename -force $self $dst
	}

    proc get_fw_release {filename} {
      debug "Getting firmware release from [file tail $filename]"
      set results [grep "^release:" $filename]
      set release [string trim [regsub "^release:" $results {}] ":"]
      return [string trim $release]
    }
    proc get_fw_build {filename} {
      debug "Getting firmware build from [file tail $filename]"
      set results [grep "^build:" $filename]
      set build [string trim [regsub "^build:" $results {}] ":"]
      return [string trim $build]
    }
    proc get_fw_target {filename} {
      debug "Getting firmware target from [file tail $filename]"
      set results [grep "^target:" $filename]
      set target [regsub "^target:" $results {}]
      return [string trim $target]
    }
    proc get_fw_auth {filename} {
      debug "Getting firmware auth from [file tail $filename]"
      set results [grep "^auth:" $filename]
      set auth [string trim [regsub "^auth:" $results {}] ":"]
      return [string trim $auth]
    }
    proc upl_xml {filename} {
      variable options
      set release [lindex $options(--spoof) 0]
      set build [lindex $options(--spoof) 1]
      set target [lindex $options(--spoof) 2]
      set bdate [lindex $options(--spoof) 3]
      set major [lindex [split $release "."] 0]
      set minor [lindex [split $release "."] 1]
      set nano "0"
      debug "Setting UPL.xml.pkg :: release to ${release} :: build to ${build},${bdate} :: target to ${target}"
      set search [::get_header_key_upl_xml $filename Version Version]
      set replace "[format %0.2d ${major}].[format %0.2d ${minor}]"
      if { $search != "" && $search != $replace } {
        set xml [::set_header_key_upl_xml $filename Version "${replace}" Version]
        if { $xml == "" } {
          die "spoof failed:: search: $search :: replace: $replace"
        }
      }
      set search [::get_header_key_upl_xml $filename Build Build]
      set replace "${build}"
      if { $search != "" && $search != $replace } {
        set xml [::set_header_key_upl_xml $filename Build "${replace}" Build]
        if { $xml == "" } {
          die "spoof failed:: search: $search :: replace: $replace"
        }
      }
      set search [::get_header_key_upl_xml $filename Product Product]
      set replace "${target}"
      if { $search != "" && $search != $replace } {
        set xml [::set_header_key_upl_xml $filename Product "${replace}" Product]
        if { $xml == "" } {
          die "spoof failed:: search: $search :: replace: $replace"
        }
      }
    }
}
