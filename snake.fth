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
100 constant delay
24 constant width  
24 constant height  
variable direction  
variable length  
variable frame
variable auf-wiedersehen
variable pause
cell 2 = [if] 13 constant a 9  constant b 7  constant c [then]
cell 4 = [if] 13 constant a 17 constant b 5  constant c [then]
cell 8 = [if] 12 constant a 25 constant b 27 constant c [then]
: seed!  dup 0= if drop 7 ( zero not allowed ) then seed ! ;
: (random) seed @ dup a lshift xor dup b rshift xor dup c lshift xor dup seed! ;
: random (random) swap mod ;
: snake-x  cells snake-x-head + ;  ( offset -- address )
: snake-y  cells snake-y-head + ;  ( offset -- address ) 
: convert-x-y 24 * + cells  ; ( x y -- offset )
: escape 27 emit ;
: reset escape ." [2J" escape ." [2;1H" ;
: uncolor escape ." [0m" ;
: green escape ." [1;32m" ;
: blue escape ." [1;44m" ;
: red escape ." [1;31m" ;
: yellow escape ." [1;33m" ;
: blink escape ." [5m" ;
: snek yellow ."  o" uncolor ;
: apple green ."  @" uncolor ;
: background ."   " ;
: wall blue ."   " uncolor ;
: pixel
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
: draw-ultra -1 rot rot draw ; ( x y -- )
: draw-white 2 rot rot draw ; ( x y -- )
: draw-gray  1 rot rot draw ; ( x y -- )
: draw-black 0 rot rot draw ; ( x y -- )
: draw-walls 
  width 0 do i 0 draw-black i height 1- draw-black loop 
  height 0 do 0 i draw-black width 1- i draw-black loop ;  
: initialize-snake 
  4 length ! length @ 1+ 0 do 12 i - i snake-x ! 12 i snake-y ! loop 
  right direction ! ;  
: set-apple-position apple-x ! apple-y ! ;  
: initialize-apple  4 4 set-apple-position ;  
: initialize 
  width 0 do height 0 do j i draw-white loop loop 
  draw-walls initialize-snake initialize-apple ;  
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
: is-horizontal  direction @ dup left = swap right = or ;  
: is-vertical    direction @ dup up = swap down = or ;  
: turn-up    is-horizontal if up direction    ! then ;  
: turn-left  is-vertical   if left direction  ! then ;  
: turn-down  is-horizontal if down direction  ! then ;  
: turn-right is-vertical   if right direction ! then ;
: >lower dup [char] A [char] Z 1+ within if $20 xor then ;
: change-direction ( key -- )
  >lower
  [char] a over = if turn-left  then 
  [char] w over = if turn-up    then 
  [char] d over = if turn-right then 
  [char] s over = if turn-down  then
  [char] q over = if 1 auf-wiedersehen ! then
  [char] p over = if pause @ 1 xor pause ! then
  drop ;  
: check-input key? if key change-direction then ;  
: wait begin key? if key change-direction exit then delay ms again ;
: hammer-time? pause @ if wait 0 pause ! then ;
: random-position width 4 - random 2 + ;  ( -- pos ) 
: move-apple 
  apple-x @ apple-y @ draw-white 
  random-position random-position 
  set-apple-position ;  
: grow-snake 1 length +! ;  
: check-apple 
  snake-x-head @ apple-x @ = 
  snake-y-head @ apple-y @ = 
  and if move-apple grow-snake then ;  
: check-collision snake-x-head @ snake-y-head @ convert-x-y graphics + @ 0<= ;
: draw-snake 
  length @ 0 do 
    i snake-x @ i snake-y @ draw-ultra
  loop 
  length @ snake-x @ 
  length @ snake-y @ 
  draw-white ;  
: draw-apple apple-x @ apple-y @ draw-gray ;  
: score frame @ length @ 10 * + ;
: display-score ." SCORE:     " blink score u. uncolor ;
: code-name
  dup 10000 >= if drop ." BIG BOSS"   exit then
  dup 5000  >= if drop ." SOLID SNAKE"  exit then
  dup 1000  >= if drop ." LIQUID SNAKE" exit then
  dup 700   >= if drop ." TROGDOR" exit then
  dup 500   >= if drop ." BLACK ADDER" exit then
  dup 200   >= if drop ." SNAKE" exit then
  drop ." SNEK" ;
: display-code ." CODE NAME: " blink score code-name uncolor ;
: fake-code ." CODE NAME: " blink ." QUITTER McQUITTERSON" uncolor ;
: au-revoir ." QUITTER!" cr display-score cr fake-code cr ;
: game-loop ( -- ) 
  begin 
    draw-snake 
    draw-apple 
    display
    delay ms
    check-input hammer-time?
    move-snake-tail 
    move-snake-head 
    check-apple 
    auf-wiedersehen @ if au-revoir cr exit then
    check-collision
  until 
  ." NO STEP ON SNEK >:C" cr display-score cr display-code cr cr ;  
: start  initialize game-loop ;  
start
bye
