" DeleteTrailingWhitespace.vim: Delete unwanted whitespace at the end of lines.
"
" DEPENDENCIES:
"   - ShowTrailingWhitespace.vim autoload script (optional)
"
" Copyright: (C) 2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.02.003	14-Apr-2012	FIX: Avoid polluting search history.
"   1.00.002	14-Mar-2012	Support turning off highlighting of trailing
"				whitespace when the user answers the query with
"				"Never" or "Nowhere".
"	001	05-Mar-2012	file creation
let s:save_cpo = &cpo
set cpo&vim

function! DeleteTrailingWhitespace#Pattern()
    let l:pattern = '\s\+$'

    " The ShowTrailingWhitespace plugin can define exceptions where whitespace
    " should be kept; use that knowledge if it is available.
    silent! let l:pattern = ShowTrailingWhitespace#Pattern(0)

    return l:pattern
endfunction

function! DeleteTrailingWhitespace#Delete( startLnum, endLnum )
    let l:save_cursor = getpos('.')
    execute  a:startLnum . ',' . a:endLnum . 'substitute/' . DeleteTrailingWhitespace#Pattern() . '//e'
    call histdel('search', -1) " @/ isn't changed by a function, cp. |function-search-undo|
    call setpos('.', l:save_cursor)
endfunction

function! DeleteTrailingWhitespace#HasTrailingWhitespace()
    " Note: In contrast to matchadd(), search() does consider the 'magic',
    " 'ignorecase' and 'smartcase' settings. However, I don't think this is
    " relevant for the whitespace mattern.
    return search(DeleteTrailingWhitespace#Pattern(), 'cnw')
endfunction

function! DeleteTrailingWhitespace#Get()
    return (exists('b:DeleteTrailingWhitespace') ? b:DeleteTrailingWhitespace : g:DeleteTrailingWhitespace)
endfunction
function! DeleteTrailingWhitespace#IsSet()
    let l:isSet = 0
    let l:value = DeleteTrailingWhitespace#Get()

    if empty(l:value) || l:value ==# '0'
	" Nothing to do.
    elseif l:value ==# 'highlighted'
	" Ask the ShowTrailingWhitespace plugin whether trailing whitespace is
	" highlighted here.
	silent! let l:isSet = ShowTrailingWhitespace#IsSet()
    elseif l:value ==# 'always' || l:value ==# '1'
	let l:isSet = 1
    else
	throw 'ASSERT: Invalid value for ShowTrailingWhitespace: ' . string(l:value)
    endif

    return l:isSet
endfunction

function! DeleteTrailingWhitespace#GetAction()
    return (exists('b:DeleteTrailingWhitespace_Action') ?
    \	b:DeleteTrailingWhitespace_Action : g:DeleteTrailingWhitespace_Action)
endfunction
function! s:RecallResponse()
    " For the response, the global settings takes precedence over the local one.
    if exists('g:DeleteTrailingWhitespace_Response')
	return g:DeleteTrailingWhitespace_Response + 5
    elseif exists('b:DeleteTrailingWhitespace_Response')
	return b:DeleteTrailingWhitespace_Response + 3
    else
	return -1
    endif
endfunction
function! DeleteTrailingWhitespace#IsAction()
    let l:action = DeleteTrailingWhitespace#GetAction()
    if l:action ==# 'delete'
	return 1
    elseif l:action ==# 'abort'
	if ! v:cmdbang && DeleteTrailingWhitespace#HasTrailingWhitespace()
	    " Note: Defining a no-op BufWriteCmd only comes into effect on the
	    " next write, but does not affect the current one. Since we don't
	    " want to install such an autocmd across the board, the best we can
	    " do is throwing an exception to abort the write.
	    throw 'DeleteTrailingWhitespace: Trailing whitespace found, aborting write (use ! to override, or :DeleteTrailingWhitespace to eradicate)'
	endif
    elseif l:action ==# 'ask'
	if v:cmdbang || ! DeleteTrailingWhitespace#HasTrailingWhitespace()
	    return 0
	endif

	let l:recalledResponse = s:RecallResponse()
	let l:response = (l:recalledResponse == -1 ?
	\   confirm('Trailing whitespace found, delete it?', "&No\n&Yes\nNe&ver\n&Always\nNowhere\nAnywhere\n&Cancel write", 1, 'Question') :
	\   l:recalledResponse
	\)
	if     l:response == 1
	    return 0
	elseif l:response == 2
	    return 1
	elseif l:response == 3
	    let b:DeleteTrailingWhitespace_Response = 0

	    if g:DeleteTrailingWhitespace_ChoiceAffectsHighlighting
		silent! call ShowTrailingWhitespace#Set(0, 0)
	    endif

	    return 0
	elseif l:response == 4
	    let b:DeleteTrailingWhitespace_Response = 1
	    return 1
	elseif l:response == 5
	    let g:DeleteTrailingWhitespace_Response = 0

	    if g:DeleteTrailingWhitespace_ChoiceAffectsHighlighting
		silent! call ShowTrailingWhitespace#Set(0, 1)
	    endif

	    return 0
	elseif l:response == 6
	    let g:DeleteTrailingWhitespace_Response = 1
	    return 1
	else
	    throw 'DeleteTrailingWhitespace: Trailing whitespace found, aborting write (use ! to override, or :DeleteTrailingWhitespace to eradicate)'
	endif
    else
	throw 'ASSERT: Invalid value for DeleteTrailingWhitespace_Action: ' . string(l:action)
    endif
endfunction

function! DeleteTrailingWhitespace#InterceptWrite()
    if DeleteTrailingWhitespace#IsSet() && DeleteTrailingWhitespace#IsAction()
	call DeleteTrailingWhitespace#Delete(1, line('$'))
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
