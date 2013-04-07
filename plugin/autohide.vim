" autohide: a Vim global plugin to automatically hide files on Windows
"   Sets the 'hidden' filesystem attribute for files created automatically by
"   Vim, and/or for files in a user-created list whenever Vim writes them.
" Last Change: 2013 Apr 06
" Maintainer: Ben Fritz <fritzophrenic@gmail.com>
" Repository/Issues list: http://vim-autohide-plugin.googlecode.com/
" License: MIT <http://opensource.org/licenses/MIT>
" Version: 2

if exists('g:loaded_autohide') || !has('win32') || v:version < 700
  finish
endif
let g:loaded_autohide = 2

let s:save_cpo=&cpo
set cpo&vim

autocmd CursorHold,CursorHoldI * call s:HideFilesOnIdle()
autocmd BufWritePost * call s:HideFilesOnWrite(expand("<afile>:p"))
autocmd VimLeave * call s:HideFilesOnExit()

function Autohide_DoHide(file)
  if exists('g:autohide_debug')
    echomsg "trying to hide" a:file
  endif
  if filewritable(a:file)
    if system('attrib /L +H '.s:SafeShellEscape(a:file)) =~? '^Invalid switch'
      " call again without the link switch if not supported
      call system('attrib +H '.s:SafeShellEscape(a:file))
    endif
  endif
  if exists('g:autohide_debug')
    echomsg system('attrib '.s:SafeShellEscape(a:file))
  endif
endfun

function s:GetTypes()
  if exists('g:autohide_types')
    return g:autohide_types
  else
    return 'suv'
  endif
endfun

function s:GetFilePatterns()
  if exists('g:autohide_file_list')
    return g:autohide_file_list
  else
    return ['.*']
  endif
endfun

function s:HideFilesOnIdle()
  let l:autohide_types = s:GetTypes()
  if l:autohide_types =~# 's' && &swapfile
    redir => l:sw_file
    silent swapname
    redir END
    call Autohide_DoHide(substitute(l:sw_file, '\n', '', 'g'))
  endif
endfun

function s:HideFilesOnWrite(file)
  let l:autohide_types = s:GetTypes()
  call s:HideFilesOnIdle()
  if l:autohide_types =~# 'u' && &undofile
    call Autohide_DoHide(undofile(a:file))
  endif
  if l:autohide_types =~# 'b' && &backup
    " note this will not work if 'backupdir' is set
    call Autohide_DoHide(fnamemodify(a:file,':r').&backupext)
  endif
  if l:autohide_types =~# 'p'
    let l:fpats = s:GetFilePatterns()
    for pattern in l:fpats
      let candidates = globpath(fnamemodify(a:file,':p:h'), pattern)
      if candidates =~? "\\(^\\|\n\\)".a:file."\\(\n\\|$\\)"
        call Autohide_DoHide(a:file)
        break
      endif
    endfor
  endif
endfun

function s:HideFilesOnExit()
  let l:autohide_types = s:GetTypes()
  if l:autohide_types =~ 'v' && !empty(&viminfo)
    if &viminfo =~ '\%(^\|,\)n'
      let l:try_file = expand(substitute(&viminfo, '\v^%(.*,)*n(\f+)', '\1', ''))
      if filewritable(l:try_file)
        let l:vnfo_file = try_file
      endif
    elseif filewritable(expand('$HOME/_viminfo'))
      let l:vnfo_file = expand('$HOME/_viminfo')
    elseif filewritable(expand('$VIM/_viminfo'))
      let l:vnfo_file = expand('$VIM/_viminfo')
    elseif filewritable(expand('C:/_viminfo'))
      let l:vnfo_file = expand('C:/_viminfo')
    endif
    if exists('l:vnfo_file')
      call Autohide_DoHide(l:vnfo_file)
    endif
  endif
endfun

" shellescape breaks on Windows using shellslash
function s:SafeShellEscape(str)
  if exists('+shellslash') && &shell=~?'\v^(\f+[/\\])?(command|cmd)'
    let ss_sav = &shellslash
    set noshellslash

    let escaped_cmd = shellescape(a:str)

    let &shellslash = ss_sav
  else
    let escaped_cmd = shellescape(a:str)
  endif
  return escaped_cmd
endfun

let &cpo=s:save_cpo
unlet s:save_cpo
