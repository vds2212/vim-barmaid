
function! LogMsg(message)
  call writefile([a:message], $MYVIMDIR . "messages.log", "a")
endfunction

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
  " call LogMsg("BufNr: " . a:buf_nr . " Listed: " . listed)
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

  if buf_type ==# 'tagbar'
    " Not Read Only
    return 1
  else
    return 0
  endif
endfunction

let g:barmaid_pause = 0

function! s:PauseBarmaid(pause)
  let g:barmaid_pause = a:pause
endfunction

function! s:KillSideBars()
  if g:barmaid_pause
    call LogMsg("barmaid_pause")
    return
  endif
  call LogMsg("Enter Windows:" . tabpagenr() . '/' . tabpagenr('$') . '-' . winnr() . '/' . winnr('$'))
  " echom "Enter Windows:" . tabpagenr() . '/' . winnr()
  " return
  let num_windows = s:GetNumNonSideBarWindows()
  " echom "Num Windows:" . num_windows
  if num_windows > 0
    " If there are non side bar windows do nothing
    return
  endif

  " Delete the terminal buffers that don't correspond to a window
  let wininfos = getwininfo()
  call filter(wininfos, "v:val.tabnr == " . tabpagenr())
  if has('nvim')
    let term_buffers = map(filter(wininfos, 'v:val.terminal'), 'v:val.bufnr')
  else
    let term_buffers = term_list()
  endif
  for buf_nr in term_buffers
    if len(win_findbuf(buf_nr)) == 0
      execute 'bd! ' . buf_nr
    endif
  endfor

  let wininfos = getwininfo()
  call filter(wininfos, "v:val.tabnr == " . tabpagenr())
  if has('nvim')
    let term_buffers = map(filter(wininfos, 'v:val.terminal'), 'v:val.bufnr')
  else
    let term_buffers = term_list()
  endif

  let buf_nr = bufnr('%')
  if index(term_buffers, buf_nr) >= 0
    " Kill the terminal buffer and quit
    " call feedkeys("\<C-w>:bd!\<CR>:quit\<CR>:\<BS>")
    call feedkeys("\<C-w>:bd!\<CR>:quit\<CR>")

  elseif !s:IsAutoClose(buf_nr)
    " Kill the side bar window
    " call feedkeys(":quit\<CR>:\<BS>")
    let l:command = ":quit\<CR>"
    if winnr('$') == 1 && tabpagenr('$') > 1
      " let g:barmaid_pause = 1
      let l:command = ":tabclose\<CR>"
    endif
    call LogMsg(command)
    call feedkeys(l:command)
  endif
endfunction

" Close Vim if the last buffer is side bar:
" autocmd BufEnter * call <SID>KillSideBars()
autocmd TabLeave * call <SID>PauseBarmaid(1)
autocmd TabEnter * call <SID>PauseBarmaid(0)
autocmd WinEnter * call <SID>KillSideBars()
