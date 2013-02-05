" send the selected text to the toplevel (either a motion or visually selected)
nnoremap <leader>c :set operatorfunc=<SID>OcamlCompile<cr>g@
vnoremap <leader>c :<c-u>call <SID>OcamlCompile(visualmode())<cr>

" send the current block to the toplevel (where a block is defined as all the
" text between this and the next set of parentheses
nnoremap <leader>e :call <SID>CompileBetween()<cr>

" send the whole file to the toplevel
nnoremap <leader>b ggVG:<c-u>call <SID>OcamlCompile(visualmode())<cr>G


autocmd WinEnter * call s:CloseIfOnlyOcamlLeft()

" Close all open buffers on entering a window if the only
" buffer that's left is the Ocaml Toplevel buffer
function! s:CloseIfOnlyOcamlLeft()
    if exists("s:ocaml_buffer") && bufwinnr(bufname(s:ocaml_buffer)) != -1 && winnr("$") == 1
        q!
    endif
endfunction

function! s:CompileBetween()
    let prev_wrap = &wrapscan
    setlocal nowrapscan

    let prev_err = v:errmsg
    let v:errmsg = ""
    execute "silent normal! ?;;\<cr>  "
    if v:errmsg != ""
        execute "normal! gg"
        let v:errmsg = ""
    endif

    execute "silent normal! v/;;\<cr> "
    if v:errmsg != ""
        return
    endif

    execute "silent normal! :\<c-u>call <SID>OcamlCompile(visualmode())\<cr>/;;\<cr>  "
    let v:errmsg = prev_err
    let &wrapscan = prev_wrap
endfunction

function! s:OpenOcaml()
    if !exists("s:ocaml_buffer") || !bufexists(s:ocaml_buffer)
        ConqueTermVSplit ocaml

        " XXX hackish way to prevent highlighting like trailing
        " whitespace highlighting in toplevel buffer. Doesn't work perfectly.
        match none /\v(.\s)*/
        let s:ocaml_buffer = bufnr("%")
        sleep 100 m
        execute "normal! \<esc>\<C-w>p"
    endif
endfunction

function! s:OcamlCompile(type)
    call <SID>OpenOcaml()

    " remember the user's previous unnamed register
    let saved_unnamed_register = @@

    " copy the desired text into the unnamed register
    if a:type ==# 'v'
        normal! `<v`>y
    elseif a:type ==# 'V'
        normal! '<v'>$y
    elseif a:type ==# "line"
        normal! '[v']$y
    elseif a:type ==# 'char'
        normal! `[v`]y
    else
        return
    endif

    " trim beginning and trailing whitespace
    let @@ = substitute(@@,'\v%^\_s+|\_s+%$','','g')

    " allw the current buffer to be hidden without deleting changes
    let prev_bufhidden = &bufhidden
    set bufhidden=hide

    " switch to the toplevel buffer
    execute "buffer " . s:ocaml_buffer
    " why does normal! break here
    execute "normal \<esc>G$p\<cr>\<esc>"
    buffer #
    " why are we in insert mode on first running compile?
    execute "set bufhidden=" . prev_bufhidden

    " move any window for the ocaml toplevel buffer to the bottom
    let prev_window = winnr()
    windo execute 'if winbufnr("%") ==# ' . s:ocaml_buffer . "|execute 'normal! G'|endif"
    execute 'normal! ' . prev_window . "\<C-w>\<C-w>"

    " restore the user's previous unnamed register
    let @@ = saved_unnamed_register
endfunction
