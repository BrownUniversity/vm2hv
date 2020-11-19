# vm2hv

## Description

Utility to assist in migration of RHEL system from ESXi to Hyper-V

## Requires

* bash
* yum

## Usage

Basic usage: *./vm2hv.sh*
This will prep a RHEL 7 or 8  for V2V conversion
to HyperV. By default it will convert and shutdown.

This script will *NOT* execute conversion without the -y,--yes option

        -y, --yes:              Execute the conversion.
        -n, --noshutdown:       Do *NOT* shutdown at the end
        -t, --test:             Show info about conversion
        -r, --restore:          Restore system files