" ============================================================================
" File:        hg_status.vim
" Description: plugin for NERD Tree that provides hg status support
" Maintainer:  Xuyuan Pang <xuyuanp at gmail dot com>
" Last Change: 4 Apr 2014
" License:     This program is free software. It comes without any warranty,
"              to the extent permitted by applicable law. You can redistribute
"              it and/or modify it under the terms of the Do What The Fuck You
"              Want To Public License, Version 2, as published by Sam Hocevar.
"              See http://sam.zoy.org/wtfpl/COPYING for more details.
" ============================================================================
if exists('g:loaded_nerdtree_hg_status')
    finish
endif
let g:loaded_nerdtree_hg_status = 1

if !exists('g:NERDTreeShowHgStatus')
    let g:NERDTreeShowHgStatus = 1
endif

if g:NERDTreeShowHgStatus == 0
    finish
endif

if !exists('g:NERDTreeMapNextHgHunk')
    let g:NERDTreeMapNextHgHunk = ']c'
endif

if !exists('g:NERDTreeMapPrevHgHunk')
    let g:NERDTreeMapPrevHgHunk = '[c'
endif

if !exists('g:NERDTreeUpdateOnWrite')
    let g:NERDTreeUpdateOnWrite = 1
endif

if !exists('g:NERDTreeUpdateOnCursorHold')
    let g:NERDTreeUpdateOnCursorHold = 1
endif

" TTL for caching the HG status before refreshing it.
" Set to 0 to avoid timed refreshes of the status cache.
if !exists('g:NERDTreeHgStatusCacheTimeExpiry')
    let g:NERDTreeHgStatusCacheTimeExpiry = 2
endif

if !exists('s:NERDTreeIndicatorMap')
    let s:NERDTreeIndicatorMap = {
                \ 'Modified'  : '✹',
                \ 'Staged'    : '✚',
                \ 'Untracked' : '✭',
                \ 'Renamed'   : '➜',
                \ 'Unmerged'  : '═',
                \ 'Deleted'   : '✖',
                \ 'Dirty'     : '✗',
                \ 'Clean'     : '✔︎',
                \ 'Unknown'   : '?'
                \ }
endif

" FUNCTION: g:NERDTreeHgStatusRefreshListener(event) {{{1
function! NERDTreeHgStatusRefreshListener(event)
    "call g:NERDTreeHgStatusRefresh()
    if !exists('b:NOT_A_HG_REPOSITORY')
        call g:NERDTreeHgStatusRefresh()
    "else 
        "Decho "Not a hg repo"
    endif

    let l:path = a:event.subject
    let l:flag = g:NERDTreeGetHgStatusPrefix(l:path)
    call l:path.flagSet.clearFlags('hg')
    if l:flag !=# ''
        call l:path.flagSet.addFlag('hg', l:flag)
    endif
endfunction

" FUNCTION: g:NERDTreeHgStatusRefresh() {{{1
" refresh cached hg status
function! g:NERDTreeHgStatusRefresh()
    "call Dfunc("NERDTreeHgStatusRefresh()")
    let b:NERDTreeCachedHgFileStatus = {}
    let b:NERDTreeCachedHgDirtyDir   = {}
    let s:HgStatusCacheDirty = 0
    let b:NOT_A_HG_REPOSITORY        = 1

    let l:root = b:NERDTreeRoot.path.str()
    let l:hgcmd = 'hg --config color.mode=false status'

    if !exists('g:NERDTreeHgStatusIgnoreSubrepositories')
        let l:hgcmd = l:hgcmd . ' -S'
    endif
    let l:hgcmd = l:hgcmd . ' .'
    let l:statusesStr = system('cd ' . l:root . ' && ' . l:hgcmd)
    "Decho("statusesStr=" . statusesStr)
    let l:statusesSplit = split(l:statusesStr, '\n')
    if l:statusesSplit != [] && l:statusesSplit[0] =~# 'abort:.*'
        let l:statusesSplit = []
        "call Dret("NERDTreeHgStatusRefresh")
        return
    endif
    let b:NOT_A_HG_REPOSITORY = 0

    for l:statusLine in l:statusesSplit
        "Decho l:statusLine 
        "" cache hg status of files

        "" remove first two chars
        let l:pathStr = substitute(l:statusLine, '..', '', '')
        "Decho l:pathStr
        let l:pathSplit = split(l:pathStr, ' -> ')
        "Decho l:pathSplit
        if len(l:pathSplit) == 2
            call s:NERDTreeCacheDirtyDir(l:pathSplit[0])
            let l:pathStr = l:pathSplit[1]
        else
            let l:pathStr = l:pathSplit[0]
        endif
        let l:pathStr = s:NERDTreeTrimDoubleQuotes(l:pathStr)
        if l:pathStr =~# '\.\./.*'
            continue
        endif
        "Decho l:statusLine[0]
        "Decho l:statusLine[1]
        let l:statusKey = s:NERDTreeGetFileHgStatusKey(l:statusLine[0])
        "Decho l:statusKey
        let b:NERDTreeCachedHgFileStatus[fnameescape(l:pathStr)] = l:statusKey

        call s:NERDTreeCacheDirtyDir(l:pathStr)
    endfor
    "call Dret("NERDTreeHgStatusRefresh")
endfunction

" FUNCTION: g:NERDTreeCacheDirtyDir() {{{1
function! s:NERDTreeCacheDirtyDir(pathStr)
    " cache dirty dir
    let l:dirtyPath = s:NERDTreeTrimDoubleQuotes(a:pathStr)
    if l:dirtyPath =~# '\.\./.*'
        return
    endif
    let l:dirtyPath = substitute(l:dirtyPath, '/[^/]*$', '/', '')
    while l:dirtyPath =~# '.\+/.*' && has_key(b:NERDTreeCachedHgDirtyDir, fnameescape(l:dirtyPath)) == 0
        let b:NERDTreeCachedHgDirtyDir[fnameescape(l:dirtyPath)] = 'Dirty'
        let l:dirtyPath = substitute(l:dirtyPath, '/[^/]*/$', '/', '')
    endwhile
endfunction

" FUNCTION: g:NERDTreeTrimDoubleQuotes() {{{1
function! s:NERDTreeTrimDoubleQuotes(pathStr)
    let l:toReturn = substitute(a:pathStr, '^"', '', '')
    let l:toReturn = substitute(l:toReturn, '"$', '', '')
    return l:toReturn
endfunction

" FUNCTION: g:NERDTreeGetHgStatusPrefix(path) {{{1
" return the indicator of the path
" Args: path
let s:HgStatusCacheTime = 0
let s:HgStatusCacheDirty = 0
function! g:NERDTreeGetHgStatusPrefix(path)
    if s:HgStatusCacheDirty || (g:NERDTreeHgStatusCacheTimeExpiry > 0 
            \ && localtime() > s:HgStatusCacheTime + g:NERDTreeHgStatusCacheTimeExpiry)
        let s:HgStatusCacheTime = localtime()
        call g:NERDTreeHgStatusRefresh()
    endif
    let l:pathStr = a:path.str()
    let l:cwd = b:NERDTreeRoot.path.str() . a:path.Slash()
    if nerdtree#runningWindows()
        let l:pathStr = a:path.WinToUnixPath(l:pathStr)
        let l:cwd = a:path.WinToUnixPath(l:cwd)
    endif
    let l:pathStr = substitute(l:pathStr, fnameescape(l:cwd), '', '')
    let l:statusKey = ''
    if a:path.isDirectory
        let l:statusKey = get(b:NERDTreeCachedHgDirtyDir, fnameescape(l:pathStr . '/'), '')
    else
        let l:statusKey = get(b:NERDTreeCachedHgFileStatus, fnameescape(l:pathStr), '')
    endif
    return s:NERDTreeGetIndicator(l:statusKey)
endfunction

" FUNCTION: s:NERDTreeGetCWDHgStatus() {{{1
" return the indicator of cwd
function! g:NERDTreeGetCWDHgStatus()
    if b:NOT_A_GIT_REPOSITORY
        return ''
    elseif b:NERDTreeCachedHgDirtyDir == {} && b:NERDTreeCachedHgFileStatus == {}
        return s:NERDTreeGetIndicator('Clean')
    endif
    return s:NERDTreeGetIndicator('Dirty')
endfunction

function! s:NERDTreeGetIndicator(statusKey)
    if exists('g:NERDTreeIndicatorMapCustom')
        let l:indicator = get(g:NERDTreeIndicatorMapCustom, a:statusKey, '')
        if l:indicator !=# ''
            return l:indicator
        endif
    endif
    let l:indicator = get(s:NERDTreeIndicatorMap, a:statusKey, '')
    if l:indicator !=# ''
        return l:indicator
    endif
    return ''
endfunction

function! s:NERDTreeGetFileHgStatusKey(us)
    if a:us ==# '?'
        return 'Untracked'
    elseif a:us ==# 'M'
        return 'Modified'
    elseif a:us ==# 'A'
        return 'Staged'
    elseif a:us ==# 'U'
        return 'Unmerged'
    elseif a:us ==# 'R'
        return 'Deleted'
    else
        return 'Unknown'
    endif
endfunction

" FUNCTION: s:jumpToNextHunk(node) {{{1
function! s:jumpToNextHunk(node)
    let l:position = search('\[[^{RO}].*\]', '')
    if l:position
        call nerdtree#echo('Jump to next hunk ')
    endif
endfunction

" FUNCTION: s:jumpToPrevHunk(node) {{{1
function! s:jumpToPrevHunk(node)
    let l:position = search('\[[^{RO}].*\]', 'b')
    if l:position
        call nerdtree#echo('Jump to prev hunk ')
    endif
endfunction

" Function: s:SID()   {{{1
function s:SID()
    if !exists('s:sid')
        let s:sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
    endif
    return s:sid
endfun

" FUNCTION: s:NERDTreeHgStatusKeyMapping {{{1
function! s:NERDTreeHgStatusKeyMapping()
    let l:s = '<SNR>' . s:SID() . '_'

    call NERDTreeAddKeyMap({
        \ 'key': g:NERDTreeMapNextHgHunk,
        \ 'scope': 'Node',
        \ 'callback': l:s.'jumpToNextHunk',
        \ 'quickhelpText': 'Jump to next hg hunk' })

    call NERDTreeAddKeyMap({
        \ 'key': g:NERDTreeMapPrevHgHunk,
        \ 'scope': 'Node',
        \ 'callback': l:s.'jumpToPrevHunk',
        \ 'quickhelpText': 'Jump to prev hg hunk' })

endfunction

augroup nerdtreehgplugin
    autocmd CursorHold * silent! call s:CursorHoldUpdate()
augroup END
" FUNCTION: s:CursorHoldUpdate() {{{1
function! s:CursorHoldUpdate()
    if g:NERDTreeUpdateOnCursorHold != 1
        return
    endif

    if !g:NERDTree.IsOpen()
        return
    endif
    let s:HgStatusCacheDirty = 1
    let l:winnr = winnr()
    call g:NERDTree.CursorToTreeWin()
    call b:NERDTreeRoot.refreshFlags()
    call NERDTreeRender()
    exec l:winnr . 'wincmd w'
endfunction

augroup nerdtreehgplugin
    autocmd BufWritePost * call s:FileUpdate(expand('%:p'))
augroup END

" FUNCTION: s:FileUpdate(fname) {{{1
function! s:FileUpdate(fname)
    if g:NERDTreeUpdateOnWrite != 1
        return
    endif
    if !g:NERDTree.IsOpen()
        return
    endif

    let l:winnr = winnr()

    call g:NERDTree.CursorToTreeWin()
    try
      let l:node = b:NERDTreeRoot.findNode(g:NERDTreePath.New(a:fname))
    catch
      return
    endtry
    if l:node == {}
        return
    endif
    let s:HgStatusCacheDirty = 1
    call l:node.refreshFlags()
    let l:node = l:node.parent
    while !empty(l:node)
        call l:node.refreshDirFlags()
        let l:node = l:node.parent
    endwhile

    call NERDTreeRender()
    exec l:winnr . 'wincmd w'
endfunction

" AUGROUP: s:AddHighlighting {{{1
augroup AddHighlighting
    autocmd FileType nerdtree call s:AddHighlighting()
augroup END
function! s:AddHighlighting()
    let l:synmap = {
                \ 'NERDTreeHgStatusModified'    : s:NERDTreeGetIndicator('Modified'),
                \ 'NERDTreeHgStatusStaged'      : s:NERDTreeGetIndicator('Staged'),
                \ 'NERDTreeHgStatusUntracked'   : s:NERDTreeGetIndicator('Untracked'),
                \ 'NERDTreeHgStatusRenamed'     : s:NERDTreeGetIndicator('Renamed'),
                \ 'NERDTreeHgStatusDirDirty'    : s:NERDTreeGetIndicator('Dirty'),
                \ 'NERDTreeHgStatusDirClean'    : s:NERDTreeGetIndicator('Clean')
                \ }

    for l:name in keys(l:synmap)
        exec 'syn match ' . l:name . ' #' . escape(l:synmap[l:name], '~') . '# containedin=NERDTreeFlags'
    endfor

    hi def link NERDTreeHgStatusModified Special
    hi def link NERDTreeHgStatusStaged Function
    hi def link NERDTreeHgStatusRenamed Title
    hi def link NERDTreeHgStatusUnmerged Label
    hi def link NERDTreeHgStatusUntracked Comment
    hi def link NERDTreeHgStatusDirDirty Tag
    hi def link NERDTreeHgStatusDirClean DiffAdd
endfunction

" FUNCTION: g:SetupListeners() {{{1
function! s:SetupListeners()
    call g:NERDTreePathNotifier.AddListener('init', 'NERDTreeHgStatusRefreshListener')
    call g:NERDTreePathNotifier.AddListener('refresh', 'NERDTreeHgStatusRefreshListener')
    call g:NERDTreePathNotifier.AddListener('refreshFlags', 'NERDTreeHgStatusRefreshListener')
endfunction

" FUNCTION: main() {{{1
if g:NERDTreeShowHgStatus && executable('hg')
    call s:NERDTreeHgStatusKeyMapping()
    call s:SetupListeners()
endif
