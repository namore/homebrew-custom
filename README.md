# Namore Custom Tap

Custom Homebrew tap for engineering tools.

## Formulae

| Formula | Description | Install |
| --- | --- | --- |
| `calculix-ccx` | Three-dimensional finite element solver (CalculiX CCX). | `brew install namore/custom/calculix-ccx` |

## Compatibility

Confirmed working on macOS 26.

## Installation

One-step install:

    brew install namore/custom/calculix-ccx

Or tap first, then install:

    brew tap namore/custom
    brew install calculix-ccx

## FreeCAD configuration

In FreeCAD (`Settings -> FEM -> CalculiX -> ccx binary path`), set:

    $(brew --prefix)/bin/ccx_2.23

## Documentation

`brew help`, `man brew`, and [Homebrew documentation](https://docs.brew.sh).
