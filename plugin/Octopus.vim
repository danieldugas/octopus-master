" File not clean Search for 'TODO:' 
" ============================================================================
" File:        Octopus.vim
" Description: Allow multiple selections, with advanced behaviours
" Maintainer:  Daniel Dugas <exodaniel at gmail dot com>
" Last Change: 20 March, 2013
" License:     This program is free software. It comes without any warranty,
"              to the extent permitted by applicable law. You can redistribute
"              it and/or modify it under the terms of the Do What The Fuck You
"              Want To Public License, Version 2, as published by Sam Hocevar.
"              See http://sam.zoy.org/wtfpl/COPYING for more details.
"
" ============================================================================
"
" SECTION: Script init stuff                             {{{1
"============================================================
" Preload and Version Check {{{2
if exists("g:loaded_octopus")
    "finish TODO: UNCOMMENT THIS, RMV NEXT LINE
    silent! call Octopus#notReal()
endif
if v:version < 700
    echo "Octopus is adapted to more recent environments. Make 
         \Octopus feel better, upgrade Vim!"
    finish
endif
let g:loaded_octopus = 1

"for line continuation - i.e dont want C in &cpo
let s:old_cpo = &cpo
set cpo&vim

" Load Class Files {{{2
call Octopus#loadClassFiles()

" Create 8 Tentacles {{{2
let g:Tentacle0 = g:OctopusTentacle.New(0)
let g:Tentacle1 = g:OctopusTentacle.New(1)
let g:Tentacle2 = g:OctopusTentacle.New(2)
let g:Tentacle3 = g:OctopusTentacle.New(3)
let g:Tentacle4 = g:OctopusTentacle.New(4)
let g:Tentacle5 = g:OctopusTentacle.New(5)
let g:Tentacle6 = g:OctopusTentacle.New(6)
let g:Tentacle7 = g:OctopusTentacle.New(7)
let g:Tentacle8 = g:OctopusTentacle.New(8)
let g:Tentacle9 = g:OctopusTentacle.New(9)
let g:Tentacles = [g:Tentacle0, g:Tentacle1, g:Tentacle2, g:Tentacle3,
                  \g:Tentacle4, g:Tentacle5, g:Tentacle6, g:Tentacle7,
                  \g:Tentacle8, g:Tentacle9 ]

" Set Tentacle Highlights {{{2
hi OctopusTentacle1Passive gui=undercurl guisp=LightRed    
hi OctopusTentacle2Passive gui=undercurl guisp=LightGreen  
hi OctopusTentacle3Passive gui=undercurl guisp=LightBlue   
hi OctopusTentacle4Passive gui=undercurl guisp=LightYellow 
hi OctopusTentacle5Passive gui=undercurl guisp=LightRed    
hi OctopusTentacle6Passive gui=undercurl guisp=LightGreen  
hi OctopusTentacle7Passive gui=undercurl guisp=LightBlue   
hi OctopusTentacle8Passive gui=undercurl guisp=LightYellow 
hi OctopusTentacle1Active  guifg=White   guibg=LightRed    
hi OctopusTentacle2Active  guifg=Black   guibg=LightGreen  
hi OctopusTentacle3Active  guifg=White   guibg=LightBlue   
hi OctopusTentacle4Active  guifg=Black   guibg=LightYellow 
hi OctopusTentacle5Active  guifg=White   guibg=LightRed    
hi OctopusTentacle6Active  guifg=Black   guibg=LightGreen  
hi OctopusTentacle7Active  guifg=White   guibg=LightBlue   
hi OctopusTentacle8Active  guifg=Black   guibg=LightYellow 

" Function: s:initVariable() function {{{2
"This function is used to initialise a given variable to a given value. The
"variable is only initialised if it does not exist prior
"
"Args:
"var: the name of the var to be initialised
"value: the value to initialise var to
"
"Returns:
"1 if the var is set, 0 otherwise
function! s:initVariable(var, value)
    if !exists(a:var)
        exec 'let ' . a:var . ' = ' . "'" . substitute(a:value, "'", "''", "g") . "'"
        return 1
    endif
    return 0
endfunction

" Init variable calls and other random constants {{{2
call s:initVariable("g:OctopusShowVirtualCursors", 1)
call s:initVariable("g:OctopusActiveHighlightPriority", 10)
call s:initVariable("g:OctopusPassiveHighlightPriority", -1)
call s:initVariable("g:OctopusCursorHighlightPriority", 100)
call s:initVariable("g:OctopusAutoAssignVisualSelection", 1)

" Init variable calls for key mappings {{{2
" call s:initVariable("g:NERDTreeMapActivateNode", "o")


" SECTION: Commands Auto-Commands and API                {{{1
"============================================================
" Commands {{{2
"init the command that users start the nerd tree with
" command! -n=? -complete=dir -bar NERDTree :call g:NERDTreeCreator.CreatePrimary('<args>')

" Auto commands {{{2
augroup Octopus
    "Save the cursor position whenever we close the nerd tree
    " exec "autocmd BufWinLeave ". g:NERDTreeCreator.BufNamePrefix() ."* call nerdtree#saveScreenState()"
augroup END

" Public API {{{2
function! CoerceColumn(l, c, ...)
    " optional arguments
    if exists('a:1')
        let option = a:1
    else
        let option = ''
    endif

    let eol = (option == 'noeol')
    let [l, c] = copy([a:l, a:c])
    let c = min([c, Cmax(l)-eol])
    let c = max([1,       c])
    return c
endfunction

function! Cmax(l)
    return col([a:l, '$']) "this includes the eol column
endfunction

function! MovePos(pos, direction, ...)
    " optional arguments
    if exists('a:1')
        let option = a:1
    else
        let option = ''
    endif

    let [l, c] = copy(a:pos)
    let eol = (option == 'noeol')
    
    if a:direction == 'up'
        let l = l-1
    endif
    if a:direction == 'down'
        let l = l+1
    endif
    if a:direction == 'left'
        if c > min([c, Cmax(l)-eol])
            let c = Cmax(l)-eol
        endif
        let c = c-1
        if c < 1
            let l = l-1
            let c = Cmax(l)-eol
        endif
    endif
    if a:direction == 'right'
        let c = c+1
        if c > min([c, Cmax(l)-eol])
            let l = l+1
            let c = 1
        endif
    endif

    return [l, c]
endfunction

function! Mod(a, b)
    let n = a:a/a:b
    return a:a - n*a:b
endfunction

" SECTION: MAPPINGS (needs to be at the end)             {{{1
"============================================================
" GENERAL MAPPINGS - TODO: user defined sequence! {{{2
nnoremap <silent> <leader>o :call Octopus#wakeOctopus('n')<CR>
vnoremap <silent> <leader>o :<C-u>call Octopus#wakeOctopus('v')<CR>
for i in range(1,8)
    execute "nnoremap <silent> <leader>".i." :<C-u>call Octopus#wakeOctopus('n', ".i.")<CR>"
    execute "vnoremap <silent> <leader>".i." :<C-u>call Octopus#wakeOctopus('v', ".i.")<CR>"
    "map <silent> <Plug>Octopus1 :<C-u>call Octopus#toggleTentacle(1)<CR>
endfor
nnoremap <silent> <leader>9 :<C-u>call Octopus#wakeOctopus('n', 'all')<CR>
vnoremap <silent> <leader>9 :<C-u>call Octopus#wakeOctopus('v', 'all')<CR>


" OCTOPUS MODE MAPPINGS {{{2
" TODO: Figure out if I can nmap instead and remove all <C-u> 
map <silent> <Plug>Octopus<Esc> :<C-u>call Octopus#keyEsc()<CR>
map <silent> <Plug>Octopus<leader>o :<C-u>call Octopus#sleepOctopus()<CR>
map <silent> <Plug>Octopus :<C-u>call Octopus#interceptKey()<CR>

for i in range(1,8)
    execute "map <silent> <Plug>Octopus<leader>".i." :<C-u>call Octopus#toggleTentacle(".i.")<CR>"
    "map <silent> <Plug>Octopus1 :<C-u>call Octopus#toggleTentacle(1)<CR>
endfor
map <silent> <Plug>Octopus<leader>9 :<C-u>call Octopus#toggleTentacle('all')<CR>

map <silent> <Plug>Octopus<leader>d :<C-u>call Octopus#clearActiveTentacles()<CR>

map <silent> <Plug>Octopusk :<C-u>call Octopus#keyMove('up')<CR>
map <silent> <Plug>Octopusj :<C-u>call Octopus#keyMove('down')<CR>
map <silent> <Plug>Octopush :<C-u>call Octopus#keyMove('left')<CR>
map <silent> <Plug>Octopusl :<C-u>call Octopus#keyMove('right')<CR>
map <silent> <Plug>Octopus<Up> :<C-u>call Octopus#keyMove('up')<CR>
map <silent> <Plug>Octopus<Down> :<C-u>call Octopus#keyMove('down')<CR>
map <silent> <Plug>Octopus<Left> :<C-u>call Octopus#keyMove('left')<CR>
map <silent> <Plug>Octopus<Right> :<C-u>call Octopus#keyMove('right')<CR>

map <silent> <Plug>Octopus<leader>s :<C-u>call Octopus#switchActiveTentacles()<CR>

" SECTION: Post Source Actions                           {{{1
"============================================================
"reset &cpo back to users setting {{{2
let &cpo = s:old_cpo
unlet s:old_cpo
" }}}
" }}}

" vim: set sw=4 tabstop=4 expandtab et fdm=marker
