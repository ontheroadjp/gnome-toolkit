if exists('g:loaded_vim_switch_us_input')
  finish
endif
let g:loaded_vim_switch_us_input = 1

let s:switch_to_us_command = [
      \ 'dbus-send',
      \ '--session',
      \ '--type=method_call',
      \ '--dest=org.gnome.Shell.Extensions.FepSwitcher',
      \ '/org/gnome/Shell/Extensions/FepSwitcher',
      \ 'org.gnome.Shell.Extensions.FepSwitcher.SwitchToUs',
      \ ]

function! s:switch_to_us() abort
  if !exists('*job_start')
    echoerr 'vim-switch-us-input requires Vim with +job support'
    return
  endif

  " Input switching is best-effort: an unavailable GNOME Shell service must
  " not block or interrupt leaving Insert mode.
  call job_start(s:switch_to_us_command, {
        \ 'in_io': 'null',
        \ 'out_io': 'null',
        \ 'err_io': 'null',
        \ })
endfunction

augroup vim_switch_us_input
  autocmd!
  autocmd InsertLeave * call <SID>switch_to_us()
augroup END
