"
" ~/.vimrc
"               ,                 .__    
"._ _  _ . .._ -+- _.*._  _  _ ._.[__)._.
"[ | )(_)(_|[ ) | (_]|[ )(/,(/,[  [__)[  

" This initializes Vim for new users (as opposed to traditional Vi users)
"source $VIMRUNTIME/defaults.vim
 
"defaults.vim -- i picked some configs
"in arch linux, at /usr/share/vim/vim82/defaults.vim

"set ttimeout		" time out for key codes
"set ttimeoutlen=100	" wait up to 100ms after Esc for special key

"set default shell syntax (also good for zsh scripts)
"check ':help ft-sh-syntax'
let g:is_bash = 1
"if you notice highlighting errors while scrolling backwards which are fixed
"when one redraws with ctrl-l, try setting the "sh_minlines" internal variable
"to a larger number. The default value is 200.
let sh_minlines = 500

" Allow backspacing over everything in insert mode.
"set backspace=indent,eol,start

" Show @@@ in the last line if it is truncated.
set display=truncate

" Do not recognize octal numbers for Ctrl-A and Ctrl-X, most users find it
" confusing.
set nrformats-=octal

" Only do this part when Vim was compiled with the +eval feature.
if 1

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  " Revert with ":filetype off".
  "filetype plugin indent on
  "see:https://vim.fandom.com/wiki/Indenting_source_code
  "
  " Use the indent of the previous line for a newly created line
  "set cindent
  "set smartindent
  set autoindent
  "smartindent and cindent might interfere with file type based
  "indentation, and should never be used in conjunction with it.
  
  " Line will continue visually indented (same amount of space as the
  " beginning of that line), thus preserving horizontal blocks of text
  "set breakindent



  " Put these in an autocmd group, so that you can revert them with:
  " ":augroup vimStartup | au! | augroup END"
  augroup vimStartup
    au!

    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid, when inside an event handler
    " (happens when dropping a file on gvim) and for a commit message (it's
    " likely a different one than last time).
    autocmd BufReadPost *
      \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
      \ |   exe "normal! g`\""
      \ | endif

  augroup END

endif

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
" Revert with: ":delcommand DiffOrig".
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif

if has('langmap') && exists('+langremap')
  " Prevent that the langmap option applies to characters that result from a
  " mapping.  If set (default), this may break plugins (but it's backward
  " compatible).
  set nolangremap
endif

"defaults.vim pick end


" Set Vim colours, either for dark or light backgrounds
set background=dark 

"Color Scheme -- background settings above may interfere
"colorscheme default 
"colorscheme anotherdark
colo inkpot
"colo jellybeans
"colo badwolf
"colo palenight
"
"Note: Color schemes are located at
" 	/usr/share/vim/vim81/colors/
" 	/home/jsn/.vim/colors/
""To check for set color scheme:
"echo g:colors_name
"Ref:https://stackoverflow.com/questions/2419624/how-to-tell-which-colorscheme-a-vim-session-currently-uses
"Ref:https://alvinalexander.com/linux/vi-vim-editor-color-scheme-colorscheme


" Screen Buffer
" Use Main Screen Buffer of XTerm to keep last Vim Buffer on screen,
" otherwise, leave buffer at Alternate Screen.
set t_ti= t_te=
"Ref:https://www.linuxquestions.org/questions/linux-general-1/disable-the-clear-after-you-close-vi-657233/
"Note: First off, it's recommended that you use screen's scrollback buffer instead.
"Since you can have multiple windows in a screen session, if you switch between
"those windows, your terminal scrollback will mix lines from all of those windows,
"but screen keeps separate scrollback buffers for each one. Just use C-a ESC
"or C-a [ to enter copy mode. One other reason for that behaviour will be the
"setting of the terminal TERM for each user.TUI applcations like vim and less
"tailor their behaviour to whatever the terminal that they find themselves 
"talking to is capable of.
"Ref:https://serverfault.com/questions/270103/gnu-screen-clearing-on-vim-less-etc-exit
"

" LESS-like Mode Options
func LessInitFunc()
	set nocursorcolumn nocursorline
	set colorcolumn=0
	"autocmd VimEnter * AnsiEsc 
endfunc
"colorscheme?
"set t_ti= t_te=
"colorsbox-faff
"Note: AnsiEsc plug-in has the same effect as RAW CONTROL CHARS in Less
"Plug-in from: http://www.drchip.org/astronaut/vim/index.html#ANSIESC
"https://www.vim.org/scripts/script.php?script_id=302
"Explanation at https://stackoverflow.com/questions/6821033/vim-how-to-run-a-command-immediately-when-starting-vim

" Size at start
"set columns=80
"set lines=35 columns=80

" Title of Vim Windows
set title
"Note: Vim will update the title according to the file being edited
" Fixed title
"set titlestring=VIM

" Try to use a window icon ( Works only in GUI VIM )
"set icon
"set iconstring=Vim


" Display cursor position always
set ruler
"Note: It is displayed at the lower right corner of the Vim window

" Ruler Formats
"
set rulerformat=%l,%c%V%=%P
" From: https://codeyarns.com/2010/11/28/vim-ruler-and-default-ruler-format/

" Line numbering
set number
"
" Set how many spaces will be preallocated to show line numbers
set numberwidth=5
"

" Cursor Lines
" Line
set cursorline
" Column
"set cursorcolumn
"Note: Useful for alignment!


" Color columns
set colorcolumn=72,77
" Make it obvious where 80 characters is


" Tab and indent options
"
" set display width of tab; 1 tab = x space with                                                           
"set tabstop=2
" transform tab to x space (x is tabstop)                                                               
"set expandtab
" auto indent; new line with number of space at the beginning same as previous
"set autoindent
" number of space append to lines when type >>
"set shiftwidth=2
"https://stackoverflow.com/questions/1878974/redefine-tab-as-4-spaces/38461002

" Set whitespace and tab chars
set listchars=tab:>-,trail:·,eol:$
" kai hendry: set list listchars=nbsp:¬,tab:»·,trail:·,extends:>
"All: set listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:␣
"Enable:
"set list

" Scroll Offset
" Minimum number of screen lines that you would like above and below
" the cursor. This option applies to all commands, including searching.
set scrolloff=4
"
" Incremental search, show results as you type
set incsearch
"
" Ignore case when searching
set ignorecase
"
" When searching try to be smart about cases 
"Obs:Needs ignorecase on!
set smartcase

" Remove useless splash screen
set shortmess+=I

" Set Menu for completion
"( Default: set )
set wildmenu

" Set Wild Menu mode
"( Default: not set )
set wildmode=longest,list,full

" Set Wild to not list files with certain patterns
"( Default: not set )
"set wildignorecase=

" Highlight Switching
"Note: This switches on syntax highlighting, but only if colors are available.
" And the 'hlsearch' option tells Vim to highlight matches with
" the last used search pattern
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif


" Matching brakets
set showmatch 
"Note: Show matching brackets when text indicator is over them
"
" Matching brakets blink duration
set matchtime=4
"Note: How many tenths of a second to blink when matching brackets


" Show partial command in the last line of screen
set showcmd
"
" Command-line line number
"set cmdheight=3
"Note: Number of screen lines to use for the command-line.


" Split panes to right and bottomi
"set splitbelow
"set splitright
"Note: May feel more natural


" Auto-reload File
set autoread
"Note: When a file has been detected to have been changed outside of Vim and
" it has not been changed inside of Vim, automatically read it again.
" When the file has been deleted this is not done


" Vim has the ability to make use of the mouse,
" but it only works for certain terminals 
"For XTerm, set mouse=a ; for xfce4-terminal use nothing or mouse=v
set mouse=a
"set mouse=v
" Ref: https://superuser.com/questions/436890/cant-copy-to-clipboard-from-vim

"Pasting from clipboard turns newlines into ^M (ctrl-m)
"TIP: use :%s/\r//g 
"https://stackoverflow.com/questions/5843495/what-does-m-character-mean-in-vim

" Confirmation messages
""set confirm
"Note: Certain operations that would normally fail because of unsaved
" changes to a buffer, e.g. ":q" and ":e", instead raise a dialog
" asking if you wish to save the current file(s)


"spelling check

"dictionaries
set spelllang=en_gb,pt_br,medicalterms-en
"medical,en-rare

"custom dictionary
set spellfile=~/.vim/spell/en.utf-8.add

"turn non spellcheck
"set spell
":setlocal spell
":setlocal spell spelllang=en_us
"see also: :help spell-quickstart
"https://www.linux.com/training-tutorials/using-spell-checking-vim/



" Searcheable Dirs list
set path+=~/.config/**,~/.cache/**,~/.fonts/**,~/.themes/**,~/.vim/**,**
"Note: This adds root dirs to your path


" WRAPPING
"
"
" Allow Wrap
set wrap
" Side-scrolling if NOWRAP
set sidescroll=5
"Note: Sidescrolling n chars at a time
"
"
" HARD WRAPPING
" Wrap margin ( Effectively puts a <EOL> at wrappping!)
"set wrapmargin=1
" To set colour of "showbreak" and the empty-line "tilda" and others:
" "hi-NonText ctermfg=Blue" at your favorite theme: Default is Blue
"
" Add <EOL> at specified line width
" (Default: disabled, nought) 
set textwidth=0
" cc=+1  " highlight column after 'textwidth'
"hi ColorColumn ctermbg=Blue
" Above option is overwwritten by color scheme colour
"
" Extra margin to the left
" (Causes textwidth to wrap more!)
"set foldcolumn=1
"
"
" SOFT WRAPPING
" Wrap long lines at a character in 'breakat' rather than at the last
" character that fits on the screen. Unlike 'wrapmargin' and 'textwidth',
" this does not insert <EOL>s in the file
set linebreak
" String to put at the start of lines that have been wrapped
"set showbreak=+++
" Display Invisible Chars (but disables soft wrapping)
"
" Previous/Next line movement
" ( Default: set whichwrap=b,s )
set whichwrap=b,s,<,>,[,],h,l
"Notes: Allow specified keys that move the cursor left/right to move to
"the previous/next line when the cursor is on the first/last character
"in the line."
" <BS> key when used at first position of line, move
" cursor to the end of previous line. <Space> key moves
" from the end of a line to the start of the next one
" in normal and editor modes
"
"If you want to keep your existing textwidth settings for most lines in your
"file, but not have Vim automatically reformat when typing on existing lines:
set formatoptions-=t



" SET SELECTION
"set clipboard=unnamed [ defaults ]
"set clipboard=unnamed
set clipboard=unnamedplus

"Copy/Paste/Cut
"if has('unnamedplus')
"  set clipboard=unnamed,unnamedplus
"endif

"PRIMARY BUFFER ACCESS ------> *Use XTerm PRIMARY_copy/paste keys!*
" Copy to PRIMARY
"nnoremap <F7> "*y
" Paste from PRIMARY
"nnoremap <F8> "*p
"Registers:
" 	* ( primary )
" 	+ ( secondary )
" 	To copy: 	To paste:
" 	"*y 		"*p
"Ref: https://stackoverflow.com/questions/11489428/how-to-make-vim-paste-from-and-copy-to-systems-clipboard
"Ref: https://vim.fandom.com/wiki/Copy,_cut_and_paste


" HISTORY AND UNDO
"
"
" History for commands, search strings,
" expressions, input() lines & debug cmds
" It does not manage Undo history!
" Default is 50; max 10000
set history=6000
"Notes: There are five separate history tables:
"- one for ':' commands                                                          
"- one for search strings                                                        
"- one for expressions                                                           
"- one for input lines, typed for the input() function.                          
"- one for debug mode commands                                                   
"Notes:                                                                          
"- When you enter a command-line that is exactly the same as an older one, the   
"  old one is removed (to avoid repeated commands moving older commands out of   
"  the history).                                                                 
"- Only commands that are typed are remembered.  Ones that completely come from  
"  mappings are not put in the history.                                          
"- All searches are put in the search history, including the ones that come      
"  from commands like "*" and "#".  But for a mapping, only the last search is   
"  remembered (to avoid that long mappings trash the history). 
"
"
" Undo history
" ( Default Set)
set undofile
" Undo levels
" ( Default: 1000 for Unix )
set undolevels=3000
" Undofile dir
" ( Default: saved at same location as the editing file )
set undodir=~/.vim/undoes
"


" BACKUP
"
" Set Backup
set backup
"
"Backup dir
set backupdir=~/.vim/bak
"
"Make a backup before overwriting a file.
set writebackup
"
" How Vim handles its renaming and moving of files
" Make a copy of the file and overwrite the original one
set backupcopy=yes
" Note: Slower but better than to rename and move file
"
" Keep first version
"set patchmode=.orig
"
" Backup extension (don't set if BufWritepre is set for backup)
"set backupext=~
" Otherwise, meaningful backup name, ex: filename@2015-04-05.14:59
" Same as incremental backups ( a new backup file every minute )
au BufWritePre * let &bex = '.bak' . strftime("%F.%Hh%Mm")
"https://gist.github.com/nepsilon/1c998cd95907ef5d2d29
"
" Skip patchmode file when pattern matches
"set backupskip [pattern]
"
"To limit the width of text to 72 characters in Mutt
au BufRead /tmp/mutt-* set tw=72


" SWAP FILES
" Set cache directory
set directory=~/.vim/swap
"recover swap files with 'vim -r file.swp'


" FILEINFO
" Fileinfo Configuration
set viminfo=%,'400,n~/.vim/viminfo
" Note: Example:
"set viminfo=%,<800,'10,/50,:100,h,f0,n~/.vim/cache/.viminfo
"            | |    |   |   |    | |  + viminfo file path
"            | |    |   |   |    | + file marks 0-9,A-Z 0=NOT stored
"            | |    |   |   |    + disable 'hlsearch' loading viminfo
"            | |    |   |   + command-line history saved
"            | |    |   + search history saved
"            | |    + files marks saved
"            | + lines saved each register (old name for <, vi6.2)
"            + save/restore buffer list
"
" The viminfo file is used to store: 
"    The command line history.
"    The search string history.
"    The input-line history.
"    Contents of non-empty registers.
"    Marks for several files.
"    File marks, pointing to locations in files.
"    Last search/substitute pattern (for 'n' and '&').
"    The buffer list.
"    Global variables.
"
" Note: To check all options available, within vim :help options
" Refs:
"https://stackoverflow.com/questions/23012391/how-and-where-is-my-viminfo-option-set
"https://vi.stackexchange.com/questions/14357/moving-viminfo-file-to-vim-dir
" About viminfo creation:
"https://bugzilla.redhat.com/show_bug.cgi?id=193150
"https://unix.stackexchange.com/questions/59155/why-is-vi-apparently-broken-viminfo-error-e576-and-how-can-i-fix-it
"https://renenyffenegger.ch/notes/development/vim/editing/viminfo/index
"


" COMMANDS & FUNCTIONS
"
"Edit .Vimrc
command Vrc !vim ~/.vimrc
"Edit .ViFMrc
command Vfrc !vim ~/.config/vifm/vifmrc
"Edit .Xresources
command Xrc !vim ~/.Xresources
"Edit .Bashrc
command Brc !vim ~/.bashrc

" Browse recent docs with scratch buffer
command Brosb :new +setl\ buftype=nofile | 
	\ 0put =v:oldfiles | execute 'g/^/m0' |
	\ nnoremap <buffer> <CR> :e <C-r>=getline('.')<CR><CR>
"Note: For full height, set :99new
" https://www.google.com/search?client=firefox-b-d&q=how+to+use+%3Aol+vim

" Select a Range of Lines instead of entering Visual Mode
command! -range Vis normal! <line1>GV<line2>G
" Ex:  :10,12Vis
" https://unix.stackexchange.com/questions/43381/select-lines-using-ranges-in-vim

" Sudo saves the file with :W 
" ( Useful for handling the permission-denied error )
command Sw w !sudo tee % > /dev/null 
" Should have the same effect as:
"command! SudoWrite w !sudo tee > /dev/null %
"https://www.reddit.com/r/vim/comments/8k4p6v/what_are_your_best_mappings/
" Note: Compare SudoWrite and SudoEdit in plug-in vim-eunuch

" Super TAB
" Install vim-supertab OR use the following function
"
"function! Smart_TabComplete()
"  let line = getline('.')                         " current line
"
"  let substr = strpart(line, -1, col('.')+1)      " from the start of the current
"                                                  " line to one character right
"                                                  " of the cursor
"  let substr = matchstr(substr, "[^ \t]*$")       " word till cursor
"  if (strlen(substr)==0)                          " nothing to match on empty string
"    return "\<tab>"
"  endif
"  let has_period = match(substr, '\.') != -1      " position of period, if any
"  let has_slash = match(substr, '\/') != -1       " position of slash, if any
"  if (!has_period && !has_slash)
"    return "\<C-X>\<C-P>"                         " existing text matching
"  elseif ( has_slash )
"    return "\<C-X>\<C-F>"                         " file matching
"  else
"    return "\<C-X>\<C-O>"                         " plugin matching
"  endif
"endfunction
"
"inoremap <tab> <c-r>=Smart_TabComplete()<CR>
"
" Ref: Function: https://vim.fandom.com/wiki/Smart_mapping_for_tab_completion
" Ref: vim-supertab: https://github.com/ervandew/supertab
"

" :w!!
" write the file when you accidentally opened it without the right (root) privileges
"cmap w!! w !sudo tee % > /dev/null
" Ref: https://github.com/charnley/dotfiles/blob/master/vimrc

" Ignore whitespace diff mode
"if &diff
"    " diff mode
"    set diffopt+=iwhite
"endif
" Check: https://github.com/charnley/dotfiles/blob/master/vimrc
"
" diff context lines around changes
":set diffopt+=context:0
"
"


" PLUG - INS
"
" VIM-EUNUCH
":Delete: Delete a buffer and the file on disk simultaneously.
":Unlink: Like :Delete, but keeps the now empty buffer.
":Move: Rename a buffer and the file on disk simultaneously.
":Rename: Like :Move, but relative to the current file's containing directory.
":Chmod: Change the permissions of the current file.
":Mkdir: Create a directory, defaulting to the parent of the current file.
":Cfind: Run find and load the results into the quickfix list.
":Clocate: Run locate and load the results into the quickfix list.
":Lfind/:Llocate: Like above, but use the location list.
":Wall: Write every open window. Handy for kicking off tools like guard.
":SudoWrite: Write a privileged file with sudo.
":SudoEdit: Edit a privileged file with sudo.
"File type detection for sudo -e is based on original file name.
"New files created with a shebang line are automatically made executable.
"New init scripts are automatically prepopulated with /etc/init.d/skeleton
"https://github.com/tpope/vim-eunuch

" VIM-SUPERTAB
"let g:SuperTabDefaultCompletionType = "context"
"
"the default is to press <CTR-X> + <CTR-O> to activate omni-completion
" the following setting means you can just press Tab instead
let g:SuperTabDefaultCompletionType = "<C-X><C-O>"
"https://vim.fandom.com/wiki/Omni_completion_popup_menu

"or:https://stackoverflow.com/questions/7722177/how-do-i-map-ctrl-x-ctrl-o-to-ctrl-space-in-terminal-vim
"inoremap <leader>, <C-x><C-o>

" INSTANT COMPLETION
"imap <Leader><Tab> <C-X><C-F>
" NOW WE CAN:
"	- Hit tab to :find by partial match
"	- Use * at the beginning or end of string to make it fuzzy
" THINGS TO CONSIDER
" 	- :b lets you autocomplete any open buffer
"https://www.youtube.com/watch?v=XA2WjJbmmoM
"


" KEYBINDINGS
"
"Note:	map = all modes
" 	   vmap = for
" 	   |------ visual(vmap) and
" 	   |------ select mode(xmap)
" 
" :map and :noremap are recursive and non-recursive versions
" of the various mapping commands. What that means is that if you do:
"	:map j gg
"	:map Q j
"	:noremap W j
" j will be mapped to gg; Q will also be mapped to gg, because j will be
" expanded for the recursive mapping. W will be mapped to j (and not to gg)
" because j will not be expanded for the non-recursive mapping.
"https://stackoverflow.com/questions/3776117/what-is-the-difference-between-the-remap-noremap-nnoremap-and-vnoremap-mapping
"
"
"Note: The only suggestion I have is not just using a single prefix like <leader>
"and instead think of prefixes as logical groupings of functionality.
"so maybe you use <space> for a lot of things, and \ for others,
"and , for yet another grouping of mappings. i don't use <leader> at all, but there are bad (yes, I think it's bad) plugins that ship with <leader> as a default <Plug> mapping. if that is your case, still set your leader, but for the mappings you write yourself, consider using explicit <space> or otherwise.
"
"
"Note: In insert mode, <C-o> allows you to execute normal mode commands
"without leaving insert mode.
"


" MISC KEYBINDDINGS
" 
" One-stroke type ":" for cmd
noremap ; :
"https://vim.fandom.com/wiki/Map_semicolon_to_colon
"
"
" Autocorrect writing two colons
noremap :: :
"
"
" If you happen to press twice...
noremap :; :
"
"
" Exits
"Prefer to use ZZ or ZQ
" Bash-like Quit
"noremap <C-D> :q<CR>
"inoremap <C-\> :q<CR>
" Other Exits
noremap ;q  :q
noremap :Q  :q
noremap ;Q  :q
noremap :Wq :wq
noremap ;Wq :wq
"
"
" Go to same line position within a wrapped line
noremap <Up>   gk
noremap <Down> gj
inoremap <Up>   <C-o>gk
inoremap <Down> <C-o>gj
"
"
" Alternative <ESC>
" Don't leave keyboard to ESC
" *Press and hold these keys*
inoremap jj <Esc>
cnoremap jj <Esc>
"inoremap \\\ <Esc>
"cnoremap \\\ <Esc>
"Note: It has to be a key combo you usually do not type!
"Ref: https://vi.stackexchange.com/questions/16963/remap-esc-key-in-vim
"imap jj <ESC>
" One user says: mapping jj to <esc> is a must have for me.
" It should be a default
"
"
" Quickly executing throw-away macros with q register
nnoremap Q @q
"
"
" Escape spaces in command-mode by pressing space twice
"cnoremap <space><space> \<space>
"

" CONTROL & SHIFT KEYS
"
"
" INDEX FOR CONTROL & UPPERCASE LETTERS ( SHIFT )
" 	C-Home 		Go to Top of document
" 	C-End 		Go to End of document
" 	
"
" Control + Home/End go to Top/Bottom of file
noremap <C-Home> gg
noremap <C-End> G
inoremap <C-Home> gg
inoremap <C-End> G  
"https://vim.fandom.com/wiki/Move_cursor_by_display_lines_when_wrapping
"https://vim.fandom.com/wiki/Moving_around
"


" FUNCTION KEYS
"
" INDEX OF Fn KEYS
"	<F1>	Recent files 
"	<F2>	Toggle Line Numbers
"	<F3>	
"	<F4>
"	<F5>
"	<F6>	Auto-Scroll
"	<F7> 	
"	<F8> 	
"	<F9>	
"	<F10>	
"	<F11>	
"	<F12>	
"Note:Fn keys do not work in GVim visual mode!!!
"
"	<> 	Copy to PRIMARY (check set clipboard )
"	<> 	Paste from PRIMARY ( idem )
"
" Recent Files
noremap <F1> :browse oldfiles<CR>
"Note: You can use '0, '1, '2, ... '9 to jump amongst recent files
"To set shortcuts for recent files :h c_#<
"E.g. :edit #<1 will open last file
"If you want to use 0-9 as marks for navigation,do not mark them manually 
"After finding your query, press q or ESC and filenumber to edit it
"
"
" Line Numbers Toggle
noremap <F2> :set number! number?<CR>
"Note: Or nnoremap <F2> :set nonumber!<CR>
"The last cmd will report state "number" or "nonumer"
"https://stackoverflow.com/questions/762515/vim-remap-key-to-toggle-line-numbering
"
"
" Auto-scrolling (Default: 3800m = 3.8 seconds)
map <F6> <C-e>:sleep 3800m<CR>j<F6>
"Note: Use CTR-C to stop
"Note: Use map not noremap
"Note: https://www.reddit.com/r/vim/comments/8k4p6v/what_are_your_best_mappings/
"


" MAPLEADER 0 ( Built-in )
" ( Default set to \ )
""let mapleader = "," 
" Suggestions: - , \ "\\" ç " " "\<Space>\<Space>"
"https://www.reddit.com/r/vim/comments/72kfsn/leader_suggestions/
"
"
" INDEX OF LEADER 0
"	\f	:find in dirs path 
"	\]	Blank line below
"	\[	Blank line above 	
"	\whs	Whitespace-trim document
"	\t	Capitalise Line As In A Title
" 	\s	Opens a shell
"	
"
" Use :find to search in selected dirs in path
noremap <Leader>f :find 
"
"
" Blank Line Insertion ( above or below )
nnoremap <leader>] mjo<Esc>`j
inoremap <localleader>] <Esc>mjo<C-o>`j
nnoremap <leader>[ mkO<Esc>`k
inoremap <localleader>[ <Esc>mkO<C-o>`k
"
"
" Search & Replace ( <Leader>c and <Leader>C )
" Change word under cursor one at a time (CASE INSENSITIVE)
nnoremap <Leader>c *``cgn
nnoremap <Leader>C #``cgN 
"Note: Replaces the word under cursor for whatever you want; after that,
" you can keep pressing . and it will keep substituting all the instances
" of the original word (ala multiple cursors). To skip, escape editor mode
" and use "n"" (as you would in a normal search). Restart at new match to
" replace.
"Note:The second mapping goes the other way around: substitutes upwards.
"https://www.reddit.com/r/vim/comments/8k4p6v/what_are_your_best_mappings/
"
"
" CASE-SENSITIVE VERSION ( <Leader>ci and <Leader>Ci )
nnoremap <Leader>cs /\<<C-R>=expand('<cword>')<CR>\>\C<CR>``cgn
nnoremap <Leader>Cs ?\<<C-R>=expand('<cword>')<CR>\>\C<CR>``cgN
"https://www.reddit.com/r/vim/comments/2p6jqr/quick_replace_useful_refactoring_and_editing_tool/
"
"
" Replace All ( <Leader>ca )
noremap <Leader>ca :%r/\<<C-r><C-w>\>//g<Left><Left>
"Note: Place cursor on top of a word and Type "\r" to activate;
" then type your word, escape back to normal and press Enter
"https://vim.fandom.com/wiki/Search_and_replace_the_word_under_the_cursor
"
"
" Convert line to "Title Case" (capitalize first letter of each word)
nnoremap <Leader>t :silent s/\<\(\w\)\(\S*\)/\u\1\L\2/g<cr>
"Note:Does not work as in (word 
"
nnoremap <Leader>s :shell<cr>
"
" Trim every superfluous whitespace from the end of every line in the current
"file. Do it now and bring the cursor back to where we started.
nnoremap <Leader>whs :let _save_pos=getpos(".") <Bar> 
    \ :let _s=@/ <Bar> 
    \ :%s/\s\+$//e <Bar> 
    \ :let @/=_s <Bar> 
    \ :nohl <Bar> 
    \ :unlet _s<Bar> 
    \ :call setpos('.', _save_pos)<Bar> 
    \ :unlet _save_pos<CR><CR> 
"
"Remove bash variable dust when possible ${VAR} --> $VAR
"from cursor to end of file
nnoremap <Leader>bdust :,$s/${\([^@*\[\]}%#^/,:]\+\)}\\|${\([*@0-9]\+\)}/$\1\2/gc

" MAPLEADER 1 ( CUSTOM LEADER ) < = >
""map = <cleader1>
" Note: In normal mode, type == to automatically indent the current line
" according to your indentation settings. This command can be used with a
" count. The = command does the same, but for motions, text objects and
" visual selections. 
" Escape spaces in command-mode by pressing space twice
"cnoremap <space><space> \<space>
"
"
" INDEX OF CLEADER 1
" 	== 	:resize +2 	
" 	== 	:resize +2 	
" 	=+ 	:resize -2 
" 	=_ 	:resize -2 
"
"
" WINDOW SPLITTING
" 
" Split and Edit New File
""nmap <cleader1>n :new<CR>
""nmap <cleader1>N :vnew<CR>
"
"Split with Fn keys
""nmap <cleader1>s :split <CR>
""nmap <cleader1>S :vsplit <CR>
"
" NAVIGATION in Split Screens
""nnoremap <cleader1>j <C-W><C-J>
""nnoremap <cleader1>k <C-W><C-K>
""nnoremap <cleader1>l <C-W><C-L>
""nnoremap <cleader1>h <C-W><C-H>
"nnoremap <C-J> <C-W><C-J>
"nnoremap <C-K> <C-W><C-K>
"nnoremap <C-L> <C-W><C-L>
"nnoremap <C-H> <C-W><C-H>
"
"
" WINDOW RESIZING
"
" Make Windows (almost) equal size
""nmap <cleader1><CR> <C-W>=
"
" Horizontal
""nmap <cleader1>= :resize +2 <CR>
""nmap <cleader1>- :resize -2 <CR>
"nmap <F10> :resize +4 <CR>
"nmap <F9> :resize -4 <CR>
"
" Vertical
" Note: Use CAPSLOCK to access + and _ more easily
""nmap <cleader1>+ :vertical:resize +2 <CR>
""nmap <cleader1>_ :vertical:resize -2 <CR>
"nmap <F12> :vertical resize +4 <CR>
"nmap <F11> :vertical resize -4 <CR>
"
" Horizontal & Vertical
" Works when Xresources XTerm.vt100.metaSendsEscape:False (Default)
"nmap ½ :resize +2 <CR>
"nmap ­ :resize -2 <CR>
"nmap « :vertical:resize +2 <CR>
"nmap ß :vertical:resize -2 <CR>
"


" MAPLEADER 2 ( CUSTOM LEADER ) < ç >
"
"map ç <cleader2>


" REFERENCES
"
" VIM KEYS AND UNUSED KEYS
"
" Legend: 'n' - not used in stock Vim
"        'y' - used in stock Vim
"        's' - synonym for something in stock Vim
"        'c' - key that continues, i.e. waits for another key; if 'showcmd' is
"              set, these are generally the cases where partial commands appear
"              on the status bar
"
"The table assumes 'insertmode' and 'allowrevins' are not set.
"
"See also <http://vim.wikia.com/wiki/Unused_keys>.
"
"     key        normal visual insert cmdline
"     ---------------------------------------
"     CTRL-@     n      n      y      n
"     CTRL-A     y      y      y      y
"     CTRL-B     y      y      n      y
"     CTRL-C     y      y      y      y
"     CTRL-D     y      y      y      y
"     CTRL-E     y      y      y      y
"     CTRL-F     y      y      y      y
"     CTRL-G     y      y      c      y
"     CTRL-H     y      y      y      y
"     CTRL-I     y      n      y      y
"     CTRL-J     s      s      s      s
"     CTRL-K     n      n      c      c
"     CTRL-L     y      y      y      y
"     CTRL-M     y      y      y      y
"     CTRL-N     s      s      y      y
"     CTRL-O     y      n      y      n
"     CTRL-P     s      s      y      y
"     CTRL-Q     s      s      s      s
"     CTRL-R     y      n      c      c
"     CTRL-S     n      n      n      n
"     CTRL-T     y      n      y      y
"     CTRL-U     y      y      y      y
"     CTRL-V     y      y      c      c
"     CTRL-W     c      c      y      y
"     CTRL-X     y      y      c      n
"     CTRL-Y     y      y      y      y
"     CTRL-Z     y      y      n      n
"     CTRL-[     n      y      y      y
"     CTRL-\     c      c      c      c
"     CTRL-]     y      y      y      y
"     CTRL-^     y      n      y      y
"     CTRL-_     n      n      n      n
"     SPACE      y      y      y      y
"     !          c      y      y      y
"     "          c      c      y      y
"     #          y      y      y      y
"     $          y      y      y      y
"     %          y      y      y      y
"     &          y      n      y      y
"     '          c      c      y      y
"     (          y      y      y      y
"     )          y      y      y      y
"     *          y      y      y      y
"     +          s      s      y      y
"     ,          y      y      y      y
"     -          y      y      y      y
"     .          y      n      y      y
"     /          y      y      y      y
"     0          y      y      y      y
"     1          y      y      y      y
"     2          y      y      y      y
"     3          y      y      y      y
"     4          y      y      y      y
"     5          y      y      y      y
"     6          y      y      y      y
"     7          y      y      y      y
"     8          y      y      y      y
"     9          y      y      y      y
"     :          y      y      y      y
"     ;          y      y      y      y
"     <          c      y      y      y
"     =          c      y      y      y
"     >          c      y      y      y
"     ?          y      y      y      y
"     @          c      y      y      y
"     A          y      y      y      y
"     B          y      y      y      y
"     C          y      y      y      y
"     D          y      y      y      y
"     E          y      y      y      y
"     F          c      c      y      y
"     G          y      y      y      y
"     H          y      y      y      y
"     I          y      y      y      y
"     J          y      y      y      y
"     K          s      y      y      y
"     L          y      y      y      y
"     M          y      y      y      y
"     N          y      y      y      y
"     O          y      y      y      y
"     P          y      s      y      y
"     Q          y      n      y      y
"     R          y      s[1]   y      y
"     S          s      y      y      y
"     T          c      c      y      y
"     U          y      y      y      y
"     V          y      y      y      y
"     W          y      y      y      y
"     X          y      y      y      y
"     Y          s      y      y      y
"     Z          c      n[2]   y      y
"     [          c      c      y      y
"     \          c      c      y      y
"     ]          c      c      y      y
"     ^          y      y      y      y
"     _          y      y      y      y
"     `          c      c      y      y
"     a          y      c      y      y
"     b          y      y      y      y
"     c          c      y      y      y
"     d          c      y      y      y
"     e          y      y      y      y
"     f          c      c      y      y
"     g          c      c      y      y
"     h          y      y      y      y
"     i          y      c      y      y
"     j          y      y      y      y
"     k          y      y      y      y
"     l          y      y      y      y
"     m          c      c      y      y
"     n          y      y      y      y
"     o          y      y      y      y
"     p          y      y      y      y
"     q          c      y      y      y
"     r          c      y      y      y
"     s          s      s      y      y
"     t          c      c      y      y
"     u          y      y      y      y
"     v          y      y      y      y
"     w          y      y      y      y
"     x          s      s      y      y
"     y          c      y      y      y
"     z          c      c      y      y
"     {          y      y      y      y
"     |          y      y      y      y
"     }          y      y      y      y
"     ~          y      y      y      y
"     DEL        s      s      y      y
"
"[1] The documentation (:help v_R) says "In a next version it might work
"    differently."
"
"[2] Z in visual mode waits for a following key, as seen if 'showcmd' is set.
"    However, neither ZZ nor ZQ do anything (as in normal mode), and no other
"    key combination is listed in the index, so it appears that Z actually does
"    nothing in visual mode.
"
"Ref: https://gist.github.com/riceissa/bcaa6b509d5561e057c1ec95af5a7d72
"Ref: https://vim.fandom.com/wiki/Unused_keys
"
"
"
"
"Ref: Good vimrc: https://github.com/thoughtbot/dotfiles/blob/master/vimrc


" Vim colors do not work in Tmux
" set Vim-specific sequences for RGB colors
"let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
"let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
"https://github.com/vim/vim/issues/993

"Some more filetypes and syntaxes
"Treat zsh syntax as bash's
au BufRead,BufNewFile *.zsh set filetype=bash
"Read ~/.rc with bash syntax
au BufRead,BufNewFile .rc set filetype=bash


" Colour and other configs
":source ~/.vimrc

"HIGHLIGHT COLOURS
"highlight ColorColumn ctermbg=DarkGray 
"hi IncSearch cterm=NONE ctermfg=darkyellow ctermbg=darkblue
"hi Search cterm=NONE ctermfg=darkblue ctermbg=darkyellow

"GUI
hi Search guibg=peru guifg=wheat
"hi IncSearch       guifg=#C4BE89 guibg=#000000

"TERMINALS
"hi Search cterm=NONE ctermfg=grey ctermbg=blue
"hi Search cterm=NONE ctermfg=darkgrey


"Parentheses highlight plugins
"Naveen Chandra: 2002 UnMtchBracket https://www.vim.org/scripts/script.php?script_id=350
"John Gilmore: 2005 https://www.vim.org/scripts/script.php?script_id=1230
"Martin Krischik: 2007 https://www.vim.org/scripts/script.php?script_id=1561
"Kien: 2013 https://github.com/kien/rainbow_parentheses.vim
"Junegunn: 2014 https://github.com/junegunn/rainbow_parentheses.vim
"https://junegunn.kr/2014/11/rainbow-parentheses
"Luochen1990: 2019 https://github.com/luochen1990/rainbow


"kien rainbow parentheses
"installed from aur
let g:rbpt_colorpairs = [
    \ ['brown',       'RoyalBlue3'],
    \ ['Darkblue',    'SeaGreen3'],
    \ ['darkgray',    'DarkOrchid3'],
    \ ['darkgreen',   'firebrick3'],
    \ ['darkcyan',    'RoyalBlue3'],
    \ ['darkred',     'SeaGreen3'],
    \ ['darkmagenta', 'DarkOrchid3'],
    \ ['brown',       'firebrick3'],
    \ ['gray',        'RoyalBlue3'],
    \ ['black',       'SeaGreen3'],
    \ ['darkmagenta', 'DarkOrchid3'],
    \ ['Darkblue',    'firebrick3'],
    \ ['darkgreen',   'RoyalBlue3'],
    \ ['darkcyan',    'SeaGreen3'],
    \ ['darkred',     'DarkOrchid3'],
    \ ['red',         'firebrick3'],
    \ ]
"
let g:rbpt_max = 16
let g:rbpt_loadcmd_toggle = 0
"
"Note: only enable compatible setting for a given language
"Note: ex: html documents highlight is incompatible with LoadChevrons
"au VimEnter * RainbowParenthesesToggle
"au VimEnter * RainbowParenthesesToggleAll
"au Syntax * RainbowParenthesesLoadRound
"au Syntax * RainbowParenthesesLoadSquare
"au Syntax * RainbowParenthesesLoadBraces
"au Syntax * RainbowParenthesesLoadChevrons


"vim surround
"all about 'surroundings'
"https://github.com/tpope/vim-surround
"vim sandwitch
"add/delete/replace surroundings of a sandwiched textobject,
"https://github.com/machakann/vim-sandwich


"json plugin
"https://vim8.org/scripts/script.php?script_id=1945
"https://github.com/elzr/vim-json
"
"try the defaults :set syntax=json


"Emmet, completion tool for HTML, CSS and JavaScript
"https://github.com/mattn/emmet-vim
"tutorial: https://raw.githubusercontent.com/mattn/emmet-vim/master/TUTORIAL
"
"if you don't want to enable emmet in all modes, you can
"set these options in vimrc
"let g:user_emmet_mode='n'    "only enable normal mode functions.
"let g:user_emmet_mode='inv'  "enable all functions, which is equal to
"let g:user_emmet_mode='a'    "enable all function in all mode.
"
"enable just for html/css
"let g:user_emmet_install_global = 0
"autocmd FileType html,css EmmetInstall
"
"to remap the default <c-y> leader:
"let g:user_emmet_leader_key='<C-Z>'
"note that the trailing , still needs to be entered, so the new
"keymap would be <c-z>,.
"
"tip: use ',' as the trigger key
let g:user_emmet_leader_key=','
"https://medium.com/vim-drops/be-a-html-ninja-with-emmet-for-vim-feee15447ef1


"netrw
"
"toggle view type with 'i'
"
"NERDtree like setup
"
let g:netrw_banner = 0
let g:netrw_liststyle = 3  "tree view
let g:netrw_browse_split = 4  "open the file in previous window
"let g:netrw_altv = 1  "change from  left to right splitting
let g:netrw_winsize = 20
"augroup ProjectDrawer
"  autocmd!
"  autocmd VimEnter * :Vexplore
"augroup END
"https://shapeshed.com/vim-netrw/#netrw---the-unloved-directory-browser

"omni complete
filetype plugin on
set omnifunc=syntaxcomplete#Complete
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags

