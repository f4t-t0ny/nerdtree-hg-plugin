nerdtree-git-plugin
===================

Mostly, this plugin is a changed/adjusted version of 
https://Xuyuanp/nerdtree-git-plugin for mercurial. Subrepos are automatically 
also shown by default. 

A plugin of NERDTree showing hg status flags. Works with the **LATEST** version of NERDTree.


## Installation

For Vundle

`Plugin 'scrooloose/nerdtree'`

`Plugin 'f4t-t0ny/nerdtree-hg-plugin'`

For NeoBundle

`NeoBundle 'scrooloose/nerdtree'`

`NeoBundle 'f4t-t0ny/nerdtree-hg-plugin'`

For Plug

`Plug 'scrooloose/nerdtree'`

`Plug 'f4t-t0ny/nerdtree-hg-plugin'`

## Configuration

Use this variable to change symbols.

```vimscript
let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ "Unknown"   : "?"
    \ }
```


## Credits

*  [Xuyuanp](https://Xuyuanp/nerdtree-git-plugin): Original git plugin
*  [scrooloose](https://github.com/scrooloose): Open API for me.
*  [git_nerd](https://github.com/swerner/git_nerd): Where my idea comes from.
*  [PickRelated](https://github.com/PickRelated): Add custom indicators & Review code.
