function! s:IsSideBar(buf_nr)
  " Return 1 if the buffer correspond to a side bar:
  " - A terminal window
  " - The quickfix window
  " - The help
  " - The NERDTree side bar
  " - ...
  let buf_type = getbufvar(a:buf_nr, '&buftype')

  if buf_type ==# 'terminal'
    let l:barmaid_terminal_is_bar = 1
    if exists("g:barmaid_terminal_is_bar")
      let l:barmaid_terminal_is_bar = g:barmaid_terminal_is_bar
    endif
    return l:barmaid_terminal_is_bar
  endif

  " This code prevent the fugitive buffer to open properly
  " if &filetype == "fugitive"
  "   return 1
  " endif

  " This code prevent the fugitive buffer to open properly
  " if !&modifiable
  "   " the non modifiable buffers
  "   " e.g.:
  "   " - fugitive
  "   " - nerdtree
  "   " - tagbar
  "   return 1
  " endif

  if buf_type ==# 'quickfix'
    " the quickfix or location lists:
    return 1
  endif

  if bufname(a:buf_nr) == ''
    " the [No Name] buffer
    return 0
  endif

  let listed = getbufvar(a:buf_nr, '&buflisted')
  if !listed
    " the not listed buffers
    " e.g.:
    " - nerdtree
    " - tagbar
    return 1
  endif

  return 0
endfunction

function! s:LeaveSideBar()
  " Go to a non side bar window
  let win_infos = getwininfo()
  let win_infos =  filter(getwininfo(), "v:val.tabnr == " . tabpagenr())
  let winindex = winnr() - 1
  for i in range(len(win_infos))
    let index = (winindex + i) % len(win_infos)
    if s:IsSideBar(win_infos[index].bufnr)
      continue
    endif
    execute (index + 1) . 'wincmd w'
    return
  endfor
endfunction

command! -bar LeaveSideBar call <SID>LeaveSideBar()

function! s:GetNumNonSideBarWindows()
  let num_windows = 0
  " echom "winnr('$'):" . winnr('$')

  for win_nr in range(1, winnr('$'))
    let buf_nr = winbufnr(win_nr)
    if s:IsSideBar(buf_nr)
      continue
    endif
    let num_windows = num_windows + 1
  endfor

  return num_windows
endfunction

function! s:IsAutoClose(buf_nr)
  " Return 1 if the side bar should already auto close
  let buf_type = getbufvar(a:buf_nr, '&filetype')

  " let term_buffers = term_list()

  if buf_type ==# 'tagbar'
    " Not Read Only
    return 1
  else
    return 0
  endif
endfunction

function! s:KillSideBars()
  let num_windows = s:GetNumNonSideBarWindows()
  " echom "Num windows: " . num_windows
  if num_windows > 0
    " If there are non side bar windows do nothing
    return
  endif

  " Delete the terminal buffers that don't correspond to a window
  let wininfos = getwininfo()
  call filter(wininfos, "v:val.tabnr == " . tabpagenr())
  if has('nvim')
    let term_buffers = map(filter(win_infos, 'v:val.terminal'), 'v:val.winnr')
  else
    let term_buffers = term_list()
  endif
  for buf_nr in term_buffers
    " echom "what about terminal: " . buf_nr
    if len(win_findbuf(buf_nr)) == 0
      " echom "delete terminal: " . buf_nr
      execute 'bd! ' . buf_nr
    endif
  endfor

  let wininfos = getwininfo()
  call filter(wininfos, "v:val.tabnr == " . tabpagenr())
  if has('nvim')
    let term_buffers = map(filter(wininfos, 'v:val.terminal'), 'v:val.winnr')
  else
    let term_buffers = term_list()
  endif
  let buf_nr = bufnr('%')
  " echom "buffer: " . buf_nr
  if index(term_buffers, buf_nr) >= 0
    " Kill the terminal buffer and quit
    " echom "terminal buffer"
    call feedkeys("\<C-w>:bd!\<CR>:quit\<CR>:\<BS>")
  elseif !s:IsAutoClose(buf_nr)
    " Kill the side bar window
    " echom "side bar"
    call feedkeys(":quit\<CR>:\<BS>")
  endif
endfunction

" Close Vim if the last buffer is side bar:
autocmd BufEnter * call <SID>KillSideBars()
