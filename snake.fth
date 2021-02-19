\ Project: Snake for Forth
\ License: Unknown?
\ Modified From: https://skilldrick.github.io/easyforth/
\ Modified by: Richard James Howe / howe.r.j.89@gmail.com
\ Repo: https://github.com/howerj/snake
\
\ It would be nice to make other terminal games for Forth, such as Sokoban,
\ Minesweeper, PacMan, Tetris, Conways Game Of Life, 2048 and Space Invaders. 
\ If they could be turned into turn-key applications, and turned into GUI
\ programs, even better.
\

only forth also definitions decimal

use snake.fb

0 constant left
1 constant up
2 constant right
3 constant down
24 constant width
24 constant height

( NB. We could store these all in one block if we bit-packed the variables )
: graphics 1 block ; ( need 576 chars )
: seed graphics 576 + ;
: inuse seed cell+ ;
: direction inuse cell+ ;
: frame direction cell+ ;
: length frame cell+ ;
: delay length cell+ ;
: apple-x delay cell+ ;
: apple-y apple-x 1+ ;
: snake-x-head 2 block ; ( need 500 )
: snake-y-head snake-x-head 512 + ; ( need 500 )

variable until-next-time
variable auf-wiedersehen
variable pause

: sleep delay @ ms ;
: seed!  dup 0= if drop 7 ( zero not allowed ) then seed ! update ;
: hi 65535 and ;
: (random) seed @ dup 13 lshift xor hi dup 9 rshift xor hi dup 7 lshift xor hi dup seed! ;
time&date + + + + + seed!
: random (random) swap mod ;
: snake-x  snake-x-head + ;  ( offset -- address )
: snake-y  snake-y-head + ;  ( offset -- address )
: score frame @ length @ 10 * + ;
: convert-x-y 24 * + ; ( x y -- offset )
: escape 27 emit ;
: cursor-hide escape ." [?25l" ;
: cursor-show escape ." [?25h" ;
: reset escape ." [2J" escape ." [2;1H" ;
: uncolor escape ." [0m" ;
: green escape ." [1;32m" ;
: blue escape ." [1;44m" ;
: red escape ." [1;31m" ;
: yellow escape ." [1;33m" ;
: blink escape ." [5m" ;
: .head red ."  ." uncolor ;
: .snake yellow ."  o" uncolor ;
: .apple green ."  @" uncolor ;
: .background ."   " ;
: .wall blue ."   " uncolor ;
: pixel
  4 over = if .head then
  3 over = if .snake then
  2 over = if .background then
  1 over = if .apple then
  0 over = if .wall then drop ;
: collides?
  4 over = if drop -1 exit then ( head )
  3 over = if drop -1 exit then ( snake )
  0 over = if drop -1 exit then drop 0 ; ( wall )
: linear-to-x-y dup width / swap height mod ;
: upper ."             THE SNAKIEST GAME IN TOWN           " cr ;
: lower ." WASD=MOVE, P=PAUSE, Q=QUIT, R/F=+/-SPEED, X=SAVE" cr ;
: stats ." SPEED=1/" delay @ 0 u.r ." ms" ( ."  SCORE=" score 0 u.r ) cr ;
: display-line ( x y -- )
    0 begin dup width < while
      2dup swap convert-x-y graphics + c@ pixel 1+
    repeat 2drop cr ;
: display-arena 0 begin dup height < while dup display-line 1+ repeat drop cr ;
: next-frame 1 frame +! update ;
: display
  cursor-hide reset upper display-arena lower stats next-frame cursor-show ;
: draw convert-x-y graphics + c! update ; ( color x y -- )
: pixel-head  4 rot rot draw ; ( x y -- )
: pixel-snake 3 rot rot draw ; ( x y -- )
: pixel-background 2 rot rot draw ; ( x y -- )
: pixel-apple  1 rot rot draw ; ( x y -- )
: pixel-wall 0 rot rot draw ; ( x y -- )
: draw-walls
  width for r@ 0 pixel-wall r@ height 1- pixel-wall next
  height for 0 r@ pixel-wall width 1- r@ pixel-wall next ;
: initialize-snake
  4 length ! update 
  length @ 1+ for 12 r@ - r@ snake-x c! 12 r@ snake-y c! next
  right direction ! update ;
: set-apple-position apple-x c! apple-y c! ;
: c+! dup >r c@ + r> c! ;
: move-up  -1 snake-y-head c+! update ;
: move-left  -1 snake-x-head c+! update ;
: move-down  1 snake-y-head c+! update ;
: move-right  1 snake-x-head c+! update ;
: move-snake-head  direction @
  left  over = if move-left  then
  up    over = if move-up    then
  right over = if move-right then
  down  over = if move-down  then
  drop ;
: move-snake-tail  length @ for
    r@ snake-x c@ r@ 1+ snake-x c!
    r@ snake-y c@ r@ 1+ snake-y c!
  next ;
: delay! 50 max 150 min delay ! update ;
: is-horizontal  direction @ dup left = swap right = or ;
: is-vertical    direction @ dup up = swap down = or ;
: turn-up    is-horizontal if up direction    ! update then ;
: turn-left  is-vertical   if left direction  ! update then ;
: turn-down  is-horizontal if down direction  ! update then ;
: turn-right is-vertical   if right direction ! update then ;
: >lower dup [char] A [char] Z 1+ within if 32 xor then ;
: change-direction ( key -- )
  >lower
  [char] a over = if turn-left  then
  [char] w over = if turn-up    then
  [char] d over = if turn-right then
  [char] s over = if turn-down  then
  [char] q over = if 1 auf-wiedersehen ! then
  [char] p over = if pause @ 1 xor pause ! then
  [char] r over = if delay @ 7 - delay! then
  [char] f over = if delay @ 7 + delay! then
  [char] x over = if 1 until-next-time ! then
  drop ;
: check-input key? if key change-direction then ;
: wait begin key? if key change-direction exit then sleep again ;
: paused blink ."                    PAUSED                       " uncolor  ;
: hammer-time? pause @ if paused cr wait 0 pause ! then ;
: random-position width 4 - random 2 + ;  ( -- pos )
: move-apple
  apple-x c@ apple-y c@ pixel-background
  random-position random-position
  set-apple-position ;
: initialize-apple 4 4 set-apple-position move-apple ;
: initialize
  inuse @ -1 = if 0 inuse ! exit then
  0 frame   ! update
  100 delay ! update
  width height * for r@ linear-to-x-y pixel-background next
  draw-walls initialize-snake initialize-apple ;
: grow-snake 1 length +! update ;
: check-apple
  snake-x-head c@ apple-x c@ =
  snake-y-head c@ apple-y c@ =
  and if move-apple grow-snake then ;
: check-collision 
   snake-x-head c@ snake-y-head c@ convert-x-y graphics + c@ collides? ;
: draw-snake
  length @ for
    r@ snake-x c@ r@ snake-y c@ pixel-snake
  next
  snake-x-head c@ snake-y-head c@ pixel-head
  length @ snake-x c@
  length @ snake-y c@
  pixel-background ;
: draw-apple apple-x c@ apple-y c@ pixel-apple ;
: display-score ." SCORE:     " blink score u. uncolor cr ;
: code-name
  dup 5000  >= if drop ." BIG BOSS"   exit then
  dup 2000  >= if drop ." SOLID SNAKE"  exit then
  dup 1500  >= if drop ." SNAKE PLISSKEN" exit then
  dup 1000  >= if drop ." LIQUID SNAKE" exit then
  dup 700   >= if drop ." TROGDOR" exit then
  dup 500   >= if drop ." BLACK ADDER" exit then
  dup 200   >= if drop ." SNAKE" exit then
  drop ." SNEK" ;
: display-code ." CODE NAME: " blink score code-name uncolor cr ;
: fake-code ." CODE NAME: " blink ." QUITTER McQUITTERSON" uncolor cr ;
: au-revoir ." QUITTER!" cr display-score fake-code ;
: see-you-again blink ." SEE YOU LATER SPACE COWBOY" uncolor cr cr ;
: die ." NO STEP ON SNEK " red  ." >:C" uncolor cr display-score display-code ;
: game-loop ( -- )
  begin
    draw-snake
    draw-apple
    display
    sleep
    check-input hammer-time?
    move-snake-tail
    move-snake-head
    check-apple
    until-next-time @ if -1 inuse ! see-you-again exit then
    auf-wiedersehen @ if au-revoir exit then
    check-collision
  until
  die cr ;
: snake initialize game-loop save-buffers ;
snake bye bye
