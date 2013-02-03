nnoremap <leader>c :set operatorfunc=<SID>OcamlCompile<cr>g@
vnoremap <leader>c :<c-u>call <SID>OcamlCompile(visualmode())<cr>
nnoremap <leader>e :call <SID>CompileBetween()<cr>
nnoremap <leader>b ggVG:<c-u>call <SID>OcamlCompile(visualmode())<cr>G

function! s:CompileBetween()
    let saved_unnamed_register = @@

;;

let x = 4;;

    setlocal nowrapscan
    normal! vG$y
    let match = matchstr(@@, ';;')
    if empty(match)
        return
    else
        execute "normal! /;;"
    endif

    execute "normal! vggy`> "
    let match = matchstr(@@, ';;')
    if empty(match)
        execute "normal! vgg:\<c-u>call <SID>OcamlCompile(visualmode())\<cr>'"
    else
        execute "normal! v?;;\<cr>  :\<c-u>call <SID>OcamlCompile(visualmode())\<cr>"
    endif

    execute "normal! /;;\<cr>  "
    let @@ = saved_unnamed_register
endfunction

function! s:OpenOcaml()
    if !exists("s:ocaml_buffer") || !bufexists(s:ocaml_buffer)
        ConqueTermVSplit ocaml
        let s:ocaml_buffer = bufnr("%")
        sleep 100 m
        execute "normal! \<esc>\<C-w>p"
    endif
endfunction

function! s:OcamlCompile(type)
    call <SID>OpenOcaml()
    let saved_unnamed_register = @@

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

    let l:prev_bufhidden = &bufhidden
    set bufhidden=hide
    execute "buffer " . s:ocaml_buffer
    " why does normal! break here
    execute "normal \<esc>G$p\<cr>\<esc>"
    buffer #
    " why are we in insert mode on first running compile?
    execute "set bufhidden=" . l:prev_bufhidden

    " move any window for the ocaml toplevel buffer to the bottom
    let l:prev_window = winnr()
    windo execute 'if winbufnr("%") ==# ' . s:ocaml_buffer . "|execute 'normal! G'|endif"
    execute 'normal! ' . l:prev_window . "\<C-w>\<C-w>"

    let @@ = saved_unnamed_register
endfunction
