\ Project: Snake for Forth
\ License: Unknown?
\ Modified From: https://skilldrick.github.io/easyforth/
\ Modified by: Richard James Howe / howe.r.j.89@gmail.com
\ Repo: https://github.com/howerj/snake
\
\ NOTES:
\
\ It would be possible to save the game using the FORTH BLOCK word-set if
\ we did some bit-shifting. This could be saved along with high-scores upon
\ quitting, so it could be resumed on entering the game again.
\
\ Redoing the loops either using FOR...NEXT loops, or using
\ BEGIN...WHILE...REPEAT would allow porting to eForth systems.
\

only forth also definitions decimal

variable seed
variable graphics 575 cells allot ( 24 * 24 = 576 cells )
variable snake-x-head 500 cells allot
variable snake-y-head 500 cells allot
variable apple-x
variable apple-y
0 constant left
1 constant up
2 constant right
3 constant down
24 constant width
24 constant height
variable delay
variable direction
variable length
variable frame
variable auf-wiedersehen
variable pause
cell 2 = [if] 13 constant a 9  constant b 7  constant c [then]
cell 4 = [if] 13 constant a 17 constant b 5  constant c [then]
cell 8 = [if] 12 constant a 25 constant b 27 constant c [then]
: sleep delay @ ms ;
: seed!  dup 0= if drop 7 ( zero not allowed ) then seed ! ;
: (random) seed @ dup a lshift xor dup b rshift xor dup c lshift xor dup seed! ;
time&date + + + + + seed!
: random (random) swap mod ;
: snake-x  cells snake-x-head + ;  ( offset -- address )
: snake-y  cells snake-y-head + ;  ( offset -- address )
: convert-x-y 24 * + cells  ; ( x y -- offset )
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
: head red ."  ." uncolor ;
: snek yellow ."  o" uncolor ;
: apple green ."  @" uncolor ;
: background ."   " ;
: wall blue ."   " uncolor ;
: pixel
   -2 over = if head then
   -1 over = if snek then
    2 over = if background then
    1 over = if apple then
    0 over = if wall then drop ;
: banner ." SNAKE KEYS: WASD = MOVEMENT, PAUSE = P, Q = QUIT" cr ;
: display
  reset
  banner
  width 0 do
    height 0 do
      i j convert-x-y graphics + @ pixel
    loop cr
  loop cr 1 frame +! ;
: draw convert-x-y graphics + ! ; ( color x y -- )
: pixel-head -2 rot rot draw ; ( x y -- )
: pixel-snek -1 rot rot draw ; ( x y -- )
: pixel-background 2 rot rot draw ; ( x y -- )
: pixel-apple  1 rot rot draw ; ( x y -- )
: pixel-wall 0 rot rot draw ; ( x y -- )
: draw-walls
  width 0 do i 0 pixel-wall i height 1- pixel-wall loop
  height 0 do 0 i pixel-wall width 1- i pixel-wall loop ;
: initialize-snake
  4 length ! length @ 1+ 0 do 12 i - i snake-x ! 12 i snake-y ! loop
  right direction ! ;
: set-apple-position apple-x ! apple-y ! ;
: move-up  -1 snake-y-head +! ;
: move-left  -1 snake-x-head +! ;
: move-down  1 snake-y-head +! ;
: move-right  1 snake-x-head +! ;
: move-snake-head  direction @
  left  over = if move-left  then
  up    over = if move-up    then
  right over = if move-right then
  down  over = if move-down  then
  drop ;
: move-snake-tail  0 length @ do
    i snake-x @ i 1+ snake-x !
    i snake-y @ i 1+ snake-y !
  -1 +loop ;
: delay! 50 max 1000 min delay ! ;
: is-horizontal  direction @ dup left = swap right = or ;
: is-vertical    direction @ dup up = swap down = or ;
: turn-up    is-horizontal if up direction    ! then ;
: turn-left  is-vertical   if left direction  ! then ;
: turn-down  is-horizontal if down direction  ! then ;
: turn-right is-vertical   if right direction ! then ;
: >lower dup [char] A [char] Z 1+ within if 32 xor then ;
: change-direction ( key -- )
  >lower
  [char] a over = if turn-left  then
  [char] w over = if turn-up    then
  [char] d over = if turn-right then
  [char] s over = if turn-down  then
  [char] q over = if 1 auf-wiedersehen ! then
  [char] p over = if pause @ 1 xor pause ! then
  [char] r over = if delay @ 20 + delay! then
  [char] f over = if delay @ 20 - delay! then
  drop ;
: check-input key? if key change-direction then ;
: wait begin key? if key change-direction exit then sleep again ;
: hammer-time? pause @ if wait 0 pause ! then ;
: random-position width 4 - random 2 + ;  ( -- pos )
: move-apple
  apple-x @ apple-y @ pixel-background
  random-position random-position
  set-apple-position ;
: initialize-apple  4 4 set-apple-position move-apple ;
: initialize
  100 delay !
  width 0 do height 0 do j i pixel-background loop loop
  draw-walls initialize-snake initialize-apple ;
: grow-snake 1 length +! ;
: check-apple
  snake-x-head @ apple-x @ =
  snake-y-head @ apple-y @ =
  and if move-apple grow-snake then ;
: check-collision snake-x-head @ snake-y-head @ convert-x-y graphics + @ 0 <= ;
: draw-snake
  length @ 0 do
    i snake-x @ i snake-y @ pixel-snek
  loop
  snake-x-head @ snake-y-head @ pixel-head
  length @ snake-x @
  length @ snake-y @
  pixel-background ;
: draw-apple apple-x @ apple-y @ pixel-apple ;
: score frame @ length @ 10 * + ;
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
    auf-wiedersehen @ if au-revoir cr exit then
    check-collision
  until
  die cr ;
: snake cursor-hide initialize game-loop cursor-show ;
snake bye bye
