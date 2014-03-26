" rails.vim - Detect a rails application
" Author:       Tim Pope <http://tpo.pe/>
" GetLatestVimScripts: 1567 1 :AutoInstall: rails.vim

" Install this file as plugin/rails.vim.

if exists('g:loaded_rails') || &cp || v:version < 700
  finish
endif
let g:loaded_rails = 1

" Utility Functions {{{1

function! s:error(str)
  echohl ErrorMsg
  echomsg a:str
  echohl None
  let v:errmsg = a:str
endfunction

" }}}1
" Detection {{{1

function! RailsDetect(...) abort
  if exists('b:rails_root')
    return 1
  endif
  let fn = substitute(fnamemodify(a:0 ? a:1 : '', ":p"),'\c^file://','','')
  let sep = exists('+shellslash') && !&shellslash ? '\\' : '/'
  if isdirectory(fn)
    let fn = fnamemodify(fn,':s?[\/]$??')
  else
    let fn = fnamemodify(fn,':s?\(.*\)[\/][^\/]*$?\1?')
  endif
  let ofn = ""
  while fn != ofn && fn !=# '/'
    if fn ==# '.'
      throw 'Rails app detection bug'
    endif
    if filereadable(fn . "/config/environment.rb")
      let b:rails_root = resolve(fn)
      return 1
    endif
    let ofn = fn
    let fn = fnamemodify(ofn,':h')
  endwhile
  return 0
endfunction

function! s:Activate(filename) abort
  if RailsDetect(a:filename)
    call rails#buffer_init()
    return 1
  endif
endfunction

" }}}1
" Initialization {{{1

if !exists('g:did_load_ftplugin')
  filetype plugin on
endif

augroup railsPluginDetect
  autocmd!
  autocmd BufNewFile,BufReadPost *
        \ if s:Activate(expand("<afile>:p")) && empty(&filetype) |
        \   call rails#buffer_settings() |
        \ endif
  autocmd VimEnter *
        \ if empty(expand("<amatch>")) && s:Activate(getcwd()) |
        \   call rails#buffer_settings() |
        \   silent doau User BufEnterRails |
        \ endif
  autocmd FileType netrw
        \ if s:Activate(expand("%:p")) |
        \   silent doau User BufEnterRails |
        \ endif
  autocmd FileType * if RailsDetect() | call rails#buffer_settings() | endif
  autocmd Syntax railslog call rails#log_syntax()
  autocmd Syntax ruby,eruby,yaml,haml,javascript,coffee,sass,scss
        \ if RailsDetect() | call rails#buffer_syntax() | endif
  autocmd BufEnter * if exists("b:rails_root")|silent doau User BufEnterRails|endif
  autocmd BufLeave * if exists("b:rails_root")|silent doau User BufLeaveRails|endif
augroup END

command! -bar -bang -nargs=* -complete=dir Rails execute rails#new_app_command(<bang>0,<f-args>)

" }}}1
" abolish.vim support {{{1

function! s:function(name)
    return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '<SNR>\d\+_'),''))
endfunction

augroup railsPluginAbolish
  autocmd!
  autocmd VimEnter * call s:abolish_setup()
augroup END

function! s:abolish_setup()
  if exists('g:Abolish') && has_key(g:Abolish,'Coercions')
    if !has_key(g:Abolish.Coercions,'l')
      let g:Abolish.Coercions.l = s:function('s:abolish_l')
    endif
    if !has_key(g:Abolish.Coercions,'t')
      let g:Abolish.Coercions.t = s:function('s:abolish_t')
    endif
  endif
endfunction

function! s:abolish_l(word)
  let singular = rails#singularize(a:word)
  return a:word ==? singular ? rails#pluralize(a:word) : singular
endfunction

function! s:abolish_t(word)
  if a:word =~# '\u'
    return rails#pluralize(rails#underscore(a:word))
  else
    return rails#singularize(rails#camelize(a:word))
  endif
endfunction

" }}}1
" vim:set sw=2 sts=2:
