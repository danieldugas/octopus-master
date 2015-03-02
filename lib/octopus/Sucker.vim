"CLASS: Sucker
"a Sucker is defined by the range it sticks to, the text in that range, and
"the id of the text highlight used to visualise the sucker
"
"exampleSucker = {range:[buffer#, stline, endline, stcol, endcol],
"                 type: 'n|v|b|l', content:'text', highlightID:id,
"                 parent: parentTentacleID}
"============================================================
let s:Sucker = {}
let g:OctopusSucker = s:Sucker

function! s:Sucker.New() "{{{1
    let newSucker = copy(self)
    let newSucker.type = ''
    let newSucker.cursorPos = 'end'
    return newSucker
endfunction
"}}}1
function! s:Sucker.updateContent() "{{{1
    let [_, l1, l2, c1, c2] = self.getRange()
    if self.type == 'n'
        let self.content = ['']
    endif
    if self.type == 'v'
        let tx = getline(l1, l2)
        let tx[-1] = tx[-1][: c2 - (&selection == 'inclusive' ? 1 : 2)]
        let tx[0] = tx[0][c1 - 1:]
        let self.content = tx
    endif
    if self.type == 'b'
        let tx = getline(l1, l2)
        for i in range(0, len(tx)-1)
            let tx[i] = tx[i][c1 - 1 : c2 - (&selection == 'inclusive' ? 1 : 2)]
        endfor
        let self.content = tx 
    endif
    if self.type == 'l'
        " TODO: line break at beginning and end?
        let tx = getline(l1, l2) + ['']
        let self.content = tx 
    endif
endfunction
"}}}1
function! s:Sucker.setType(type) "{{{1
    let self.type = a:type
endfunction
"}}}1
function! s:Sucker.setRange(range) "{{{1
" TODO: move this to getRangeExpression() to preserve order?
    let [l1, l2] = copy(a:range[1:2]) 
    let [c1, c2] = copy(a:range[3:4])
    if l1 > l2 || (l1 == l2 && c1 > c2)
        let [l2, l1] = a:range[1:2]
        let [c2, c1] = a:range[3:4]
        call self.toggleCursorPos()
    endif
    if self.type == 'l'
        let c2 = col([l2, '$'])
    endif
    let self.range = copy([a:range[0],l1,l2,c1,c2])
endfunction
"}}}1
function! s:Sucker.toggleCursorPos() "{{{1
    if self.cursorPos == 'start'
        let self.cursorPos = 'end'
    else
        let self.cursorPos = 'start'
    endif
endfunction 

function! s:Sucker.move(direction) "{{{1 
    let [bnum, l1, l2, c1, c2] = self.getRange()

    if self.type == 'n' || self.type == 'i'
        let [l1, c1] = MovePos([l1, c1], a:direction, 'noeol')
        let [l2, c2] = MovePos([l2, c2], a:direction, 'noeol')
    else
        if self.cursorPos == 'start'
            let [l1, c1] = MovePos([l1, c1], a:direction, '')
        else
            let [l2, c2] = MovePos([l2, c2], a:direction, '')
        endif
    endif
    call self.setRange([bnum, l1, l2, c1, c2])
    call self.updateContent()
endfunction
"}}}1
function! s:Sucker.highlight(style) "{{{1 "style is either 'Active' or 'Passive'
    " Handle Arguments {{{2
    if a:style != 'Active' && a:style != 'Passive'
        echoerr "'" .  a:style . "' is not a known highlight style (accepted styles are 'Passive', 'Active' )."
        let highlightPriority = g:OctopusActiveHighlightPriority
    else
        execute "let highlightPriority = g:Octopus" . a:style . "HighlightPriority"
    endif "}}}2
    call self.unHighlight()
    if exists('self.parent')
        if 1 <= self.parent && self.parent <= 8
            let self.highlightID = matchadd("OctopusTentacle" . self.parent . a:style,
            \join(self.getRangeExpression(), '\|'), highlightPriority )
        endif
    else
        let self.highlightID = matchadd("Visual",
        \join(self.getRangeExpression(), '\|'),
        \ highlightPriority )
    endif
    unlet highlightPriority
endfunction
"}}}1
function! s:Sucker.unHighlight() "{{{1
    if exists('self.highlightID')
        "TODO: when not silent! errors are observed!
        "Reason has been found: deepcopies created 
        "in the octopus function create duplicate 
        "highlight ID. 
        "the current solution (silent!) is not very
        "elegant, clean it maybe.
        silent! call matchdelete(self.highlightID)
        unlet self.highlightID
    endif
endfunction
"}}}1
function! s:Sucker.highlightCursor(toggle) "{{{1
    if exists('self.cursorHighlightID')
        "TODO: see unHighlight() TODO
        silent! call matchdelete(self.cursorHighlightID)
        unlet self.cursorHighlightID
    endif
    if a:toggle
        let self.cursorHighlightID = matchadd("Cursor",
        \self.getCursorRangeExpression(), g:OctopusCursorHighlightPriority )
    endif
endfunction
"}}}1
function! s:Sucker.getRange() "{{{1
    return copy(self.range)
endfunction
"}}}1
function! s:Sucker.getRangeExpression() "{{{1
    let [_, l1, l2, c1, c2] = self.getRange()
    
    let c1 = CoerceColumn(l1, c1)
    let c2 = CoerceColumn(l2, c2)
    " TODO: more edge cases!
    " TODO: v instead of c (virtual columns)?
    if self.type == 'n'
         "TODO: Handle this better (don't call matchadd in highlight functions)
         return ['a\^']
    endif
    if self.type == 'v'
        return ['\%'.max([l1, 0]).'l\%>'.max([c1-1, 0]).'c\_.*'.'\%<'.(c2+1).'c\_.'.'\%'.(l2).'l']
        " return ['\%>'.max([l1-1, 0]).'l\%>'.max([c1-1, 0]).'c\_.*'.'\%<'.(c2+1).'c\_.'.'\%<'.(l2+1).'l']
    endif
    if self.type == 'b'
        "TODO return one range per line
        let cmin = max([0,  min([c1, c2])-1 ])
        let cmax = max([c1, c2])+1
        let temp = []
        for l in range(l1, l2)
              let temp = temp + ['\%'.l.'l\%>'.cmin.'c\_.*\%<'.cmax.'c\_.\%'.l.'l']
        endfor
        return temp
    endif
    if self.type == 'l'
        return ['\%>'.max([l1-1, 0]).'l\_.*\%<'.(l2+1).'l\_.']
    endif
endfunction
"}}}1
function! s:Sucker.getCursorRange() "{{{1
    if self.cursorPos == 'end'
        let [l, _, c] = self.range[2:4]
    endif
    if self.cursorPos == 'start'
        let [l, _, c] = self.range[1:3]
    endif
    return [l, c]
endfunction
"}}}1
function! s:Sucker.getCursorRangeExpression() "{{{1
    let [l, c] = self.getCursorRange()
    
    if count( ['v','b','l'], self.type ) 
        let c = CoerceColumn(l, c)
    endif
    if count( ['n'], self.type )
        let c = CoerceColumn(l, c, 'noeol')
    endif

    return '\%'.l.'l\%'.(c+(c==0)).'c\_.' "TODO: This highlights eols, but makes octopus slow
    "return '\%'.l.'l\%'.(c+(c==0)).'c.'
endfunction
"}}}1
function! s:Sucker.replaceContent(sucker) "{{{1
    let OtherSucker = a:sucker
    let content = copy(OtherSucker.content) "TODO: Escape content for search and replace
    if OtherSucker.type == 'l' || OtherSucker.type == 'v'
        let content = [join(content, '\r')]
    endif
    
    " TODO: how do I deal with unequal amount of lines in block visual?
    " solution here is that I cycle the content within the line range
    " a   in 5 lines becomes   a
    " b                        b
    " c                        c
    "                          a
    "                          b
    " MAKE A BETTER SOLUTION FOR B-VISUAL, F. EXAMPLE:
    " if there are more content lines than range lines
    " find the amount of lines in the content to copy
    " replace the first line by the first line of the content
    " if there isn't another line, move down and get same rg.expr
    " if there are less, replace up to last available content line
    " then replace the others by ''
    for i in range(0, len(self.getRangeExpression())-1 )
        call feedkeys("l") "TODO: DEBUG UNCOMMENT
        execute "% s:". self.getRangeExpression()[i].":".content[Mod(i, len(content))].":c"
    endfor
endfunction
"}}}1

" vim: set sw=4 tabstop=4 expandtab et fdm=marker
