# Vim-Barmaid
A Vim/Neovim plugin that manage automatically side bars.

## Introduction

Some Vim/Neovim plugin introduce side bars.
e.g.:
- Neo-Tree introduces a right panel to display the folder hierarchy
- Vim-Fugitive introduces a bottom window with the files to stage or commit
- TagBar introduce a right panel to display the structure of the code
- ...

Some Vim/Neovim window are not intented to contains user files.
e.g.:
- QuickFix window
- LocationList window

The Barmaid plugin automatically `quit` these window when the last 'real' user window of the tab is closed.

## Commands

The plugin introduces the following commands:
- LeaveSideBar

## Requirements

Tested on Vim >= 8.2 and Neovim >= 0.8.3


## Installation

For [vim-plug](https://github.com/junegunn/vim-barmaid) users:
```vim
Plug 'vds2212/vim-barmaid'
```

