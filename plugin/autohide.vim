" autohide: a Vim global plugin to automatically hide files on Windows
"   Sets the 'hidden' filesystem attribute for files created automatically by
"   Vim, and/or for files in a user-created list whenever Vim writes them.
" Last Change: 2013 Apr 03
" Maintainer: Ben Fritz <fritzophrenic@gmail.com>
" License: MIT <http://opensource.org/licenses/MIT>
" Version: 1

if exists('g:loaded_autohide') || !has('win32') || v:version < 700
  finish
endif
let g:loaded_autohide = 1

let s:save_cpo=&cpo
set cpo&vim

autocmd CursorHold,CursorHoldI * call Autohide_HideFilesOnIdle()
autocmd BufWritePost * call Autohide_HideFilesOnWrite(expand("<afile>:p"))
autocmd VimLeave * call Autohide_HideFilesOnExit()

function Autohide_DefaultOptions()
  if exists('g:autohide_types')
    return g:autohide_types
  else
    return 'suv'
  endif
endfun

function Autohide_HideFilesOnIdle()
  let l:autohide_types = Autohide_DefaultOptions()
  if l:autohide_types =~# 's' && &swapfile
    redir => l:sw_file
    silent swapname
    redir END
    call Autohide_DoHide(substitute(l:sw_file, '\n', '', 'g'))
  endif
endfun

function Autohide_HideFilesOnWrite(file)
  let l:autohide_types = Autohide_DefaultOptions()
  call Autohide_HideFilesOnIdle()
  if l:autohide_types =~# 'u' && &undofile
    call Autohide_DoHide(undofile(a:file))
  endif
  if l:autohide_types =~# 'b' && &backup
    " note this will not work if 'backupdir' is set
    call Autohide_DoHide(fnamemodify(a:file,':r').&backupext)
  endif
endfun

function Autohide_HideFilesOnExit()
  let l:autohide_types = Autohide_DefaultOptions()
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

function Autohide_DoHide(file)
  if exists('g:autohide_debug')
    echomsg "trying to hide" a:file
  endif
  if filewritable(a:file)
    if system('attrib /L +H '.Autohide_SafeShellEscape(a:file)) =~? '^Invalid switch'
      " call again without the link switch if not supported
      call system('attrib +H '.Autohide_SafeShellEscape(a:file))
    endif
  endif
  if exists('g:autohide_debug')
    echomsg system('attrib '.Autohide_SafeShellEscape(a:file))
  endif
endfun

" shellescape breaks on Windows using shellslash
function Autohide_SafeShellEscape(str)
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
