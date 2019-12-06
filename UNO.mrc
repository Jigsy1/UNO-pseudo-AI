; UNO pseudo "AI" (Extended) v2 - For playing against: http://hawkee.com/snippet/5301/

#UNO on
; Settings

alias -l UNO.bot { return UNO }
alias -l UNO.chan { return #UNO }
alias -l UNO.network { return UNO }

; Definitions

alias -l UNO.deal.time { return 20 }
; `-> Seconds before (re)dealing.
alias -l UNO.enum { return B,G,R,Y }
alias -l UNO.hand { return UNO.Hand }
; `-> Hash table only.
alias -l UNO.limit.join { return 0 }
; `-> Only join games that'll have a certain number of players.
alias -l UNO.limit.to { return $iif($hget(UNO,JoinMin),$v1,3) }
; `-> Basically, only join if there are already X players.
alias -l UNO.limit.rand { return 1 }
; `-> Set a random JoinMin number. 0: no | 1: yes
alias -l UNO.random { return 0 }
; `-> Random attack pattern. 0: no | 1: yes
alias -l UNO.skip.enum { return DT,S }
; `-> Technically R (currently broken) should be here if there's only two players since it functions as another S.
alias -l UNO.sort { return 1 }
; `-> Sort the cards. E.g. DT 9 3 S R 4 -> DT S R 3 4 9 - 0: no | 1: yes

; Commands

alias -l UNO.deal { return !deal }
alias -l UNO.draw { return !draw }
alias -l UNO.join { return !join }
alias -l UNO.pass { return !pass }
alias -l UNO.play { return !play }

on *:disconnect:{ uno_stop }
on me:*:kick:#:{
  if (($chan == $UNO.chan) && ($network == $UNO.network)) { uno_stop }
}
on *:notice:*:?:{
  if (($nick == $UNO.bot) && ($network == $UNO.network)) {
    hadd -m UNO str $remove($1-,,)
    tokenize 32 $strip($1-)
    if (Type $UNO.deal to start the game* iswm $1-) {
      if ($hget(UNO,Count) >= 2) { .timeruno.deal 1 $UNO.deal.time msg $UNO.chan $UNO.deal }
      else { uno_attempt_redeal }
      ; `-> Wait until another player joins before dealing.
    }
    if (You drew:* iswm $1-) {
      uno_add_card $gettok($hget(UNO,str),3,32)
      .timeruno.uno_play_hand_b 1 3 uno_play_hand b $hget(UNO,Top)
    }
    if (Your cards:* iswm $1-) { uno_set_hand $gettok($hget(UNO,str),3-,32) }
    ; `-> Destroy and set the hash table each time. It's a hacky way of doing it; but it works.
  }
}
on me:*:part:#:{
  if (($chan == $UNO.chan) && ($network == $UNO.network)) { uno_stop }
}
on *:text:*:#:{
  if (($nick == $UNO.bot) && ($network == $UNO.network)) {
    hadd -m UNO str $remove($1-,,)
    tokenize 32 $strip($1-)
    if ((Congratulations*you win!!! iswm $1-) || (Game ended* iswm $1-) || ($me has been kicked from the game* iswm $1-)) { uno_stop }
    if (*has started UNO* iswm $1-) {
      if (!$istok($1-,$me,32)) {
        if ($UNO.limit.join == 0) { uno_join_game }
        else {
          if (($UNO.limit.rand == 1) && (!$hget(UNO,JoinMin))) { hadd -m UNO JoinMin $rand(3,5) }
        }
      }
      ; `-> Just to stop joining games I've started.
    }
    if (* $+ $+($me,'s) turn* iswm $1-) {
      if ($1 != Its) { .timeruno.uno_play_hand_a 1 3 uno_play_hand_a }
      ; `-> Just ignore @count...
    }
    if (Top card:* iswm $1-) { hadd -m UNO Top $gettok($hget(UNO,str),3,32) }
    if (*will be player* iswm $1-) {
      hadd -m UNO Count $left($4,-1)
      if (!$istok($1-,$me,32)) {
        if ((!$hget(UNO,Joined)) && ($UNO.limit.join == 1) && ($hget(UNO,Count) >= $UNO.limit.to)) { uno_join_game }
      }
      else { hadd -m UNO Joined 1 }
    }
  }
}
on *:unload:{ uno_stop }

alias -l color_as_long { return blue B,green G,red R,yellow Y }
alias -l color_to_card { return $gettok($matchtok(01 W¦12 B¦09 G¦04 R¦08 Y,$1,1,166),2,32) }
alias -l comma { return $chr(44) }
alias -l count_no_skips {
  if ($istok($UNO.skip.enum,R,44)) {
    if ($hget(UNO,Count) > 2) { var %R = 0 }
    ; `-> R is useless for skipping with more than two players.
    else { var %R = $count($hget($UNO.Hand,$1),R) }
  }
  else { var %R = 0 }
  return $calc($numtok($hget($UNO.Hand,$1),32) - ($count($hget($UNO.Hand,$1),DT) + %R + $count($hget($UNO.Hand,$1),S)))
}
alias -l deck_check {
  ; $deck_check(<card>,<excluded color>)
  var %thisCard = $1, %thisColor = $2
  return $calc($left($regsubex($str(.,3),/./g,$iif($istok($hget($UNO.Hand,$gettok($remtok($UNO.enum,%thisColor,44),\n,44)),%thisCard,32),1+,0+)),-1))
}
alias -l have_card {
  ; $have_card(<card>,<excluded color>)
  var %thisCard = $1, %thisColor = $2
  return $left($regsubex($str(.,3),/./g,$iif($istok($hget($UNO.Hand,$gettok($remtok($UNO.enum,%thisColor,44),\n,44)),%thisCard,32),$+($gettok($remtok($UNO.enum,%thisColor,44),\n,44),$comma))),-1)
}
alias -l least_cards_by_color {
  var %thisEnum = $iif($1,$v1,$UNO.enum), %thisResult = $regsubex($str(.,$numtok(%thisEnum,44)),/./g,$+($numtok($hget($UNO.Hand,$gettok(%thisEnum,\n,44)),32),¦))
  return $iif($gettok(%thisEnum,$findtok(%thisResult,$gettok($sorttok(%thisResult,166,n),1,166),1,166),44),$v1,$randtok($UNO.enum,44))
}
alias -l most_cards_by_color {
  var %thisEnum = $iif($1,$v1,$UNO.enum), %thisResult = $regsubex($str(.,$numtok(%thisEnum,44)),/./g,$+($numtok($hget($UNO.Hand,$gettok(%thisEnum,\n,44)),32),¦))
  return $iif($gettok(%thisEnum,$findtok(%thisResult,$gettok($sorttok(%thisResult,166,nr),1,166),1,166),44),$v1,$randtok($UNO.enum,44))
}
; `-> Pick a random color on the off chance something goes wrong. (E.g. A hand full of wilds.)
alias -l randtok { return $gettok($1,$rand(1,$numtok($1,$iif($2,$v1,32))),$iif($2,$v1,32)) }
alias -l unotok { return $str($+($chr(32),R),$count($1,R)) $sorttok($remtok($1,R,0,$2),$2,$3) }
; `-> Since R is broken, place it in a way which won't fuck up mapping. (Either at the start or at the end.)
alias -l uno_add_card {
  ; /uno_add_card <card>
  tokenize 32 $base($gettok($remove($1,,),1,91),10,10,2) $left($gettok($remove($1,,),2,91),-1)
  hadd -m $UNO.Hand $color_to_card($1) $iif($UNO.sort == 1,$iif($hget(UNO,Count) > 2,$sorttok($2 $hget($UNO.Hand,$color_to_card($1)),32,n),$unotok($2 $hget($UNO.Hand,$color_to_card($1)),32,n)),$2 $hget($UNO.Hand,$color_to_card($1)))
}
alias -l uno_attempt_redeal {
  if ($hget(UNO,Count) >= 2) { msg $UNO.chan $UNO.deal }
  else { .timeruno.deal 1 $UNO.deal.time uno_attempt_redeal }
}
alias -l uno_join_game { .timeruno.join 1 $rand(2,8) msg $UNO.chan $UNO.join }
alias -l uno_play_hand {
  ; /uno_play_hand <a|b> <top card>
  ; `-> a: 1st try (pre draw) | b: 2nd try (post draw)
  var %thisTurn = $1
  tokenize 32 $base($gettok($remove($2,,),1,91),10,10,2) $left($gettok($remove($2,,),2,91),-1)
  var %thisColor = $color_to_card($1)
  if ($hget($UNO.Hand,%thisColor)) {
    ; `-> Color match.
    var %thisList = $v1
    var %thisResult = $regsubex($str(.,$numtok(%thisList,32)),/./g,$+($deck_check($gettok(%thisList,\n,32),%thisColor),¦))
    ; `-> Now check if the card is elsewhere in my hand - regardless of color - then play a card depending on how little I have.
    if ($findtok(%thisResult,0,$iif($UNO.random == 1,$rand(1,$iif($count(%thisResult,0) > 1,$v1,1)),1),166)) { var %thisToken = $v1 | goto uno_play_card }
    if ($findtok(%thisResult,1,$iif($UNO.random == 1,$rand(1,$iif($count(%thisResult,1) > 1,$v1,1)),1),166)) { var %thisToken = $v1 | goto uno_play_card }
    if ($findtok(%thisResult,2,$iif($UNO.random == 1,$rand(1,$iif($count(%thisResult,2) > 1,$v1,1)),1),166)) { var %thisToken = $v1 | goto uno_play_card }
    if ($findtok(%thisResult,3,$iif($UNO.random == 1,$rand(1,$iif($count(%thisResult,3) > 1,$v1,1)),1),166)) { var %thisToken = $v1 | goto uno_play_card }
    ; |- Try and condense this code down into less lines if possible.
    ; `-> 0 = zero matches elsewhere. 1 = one match elsewhere. 2 = etc. 3 = etc.
    :uno_play_card
    msg $UNO.chan $UNO.play %thisColor $gettok($hget($UNO.Hand,%thisColor),%thisToken,32)
    goto uno_end_turn
  }
  else {
    ; `-> We don't have any cards that match this color. Do we have a matching type instead? E.g. R S->B S
    if ($have_card($2,%thisColor)) {
      var %thisHave = $v1
      if (($istok($UNO.skip.enum,$2,44)) && ($numtok($have_card($2,%thisColor),44) > 1)) {
        ; |- Note: Untested.
        ; `-> Make sure it plays the color of the least amount of cards first assuming that COLOR->(NUMBER_OF_CARDS - (NUMBER_OF_DT + NUMBER_OF_R + NUMBER_OF_S)) = 0; otherwise, play the most.
        var %thisResult = $regsubex($str(.,$numtok(%thisHave,44)),/./g,$+($gettok(%thisHave,\n,44),:,$numtok($hget($UNO.Hand,$gettok(%thisHave,\n,44)),32),=,$count_no_skips($gettok(%thisHave,\n,44)),¦))
        var %thisMatch = $gettok($matchtok(%thisResult,=0,$rand(1,$matchtok(%thisResult,=0,0,166)),166),1,58)
        ; |-> Not random. E.g. G:4=3¦R:2=0¦Y:1=0 means it'll pick R first rather than yellow. (Or R rather than R or Y.)
        ; `---^-> Ignore this; it should now be random.
        msg $UNO.chan $UNO.play $iif(%thisMatch,$v1,$least_cards_by_color($have_card($2,%thisColor))) $2
        goto uno_end_turn
      }
      msg $UNO.chan $UNO.play $most_cards_by_color($have_card($2,%thisColor)) $2
      goto uno_end_turn
    }
    else {
      ; `-> No matching type either. Oh well, play a W(D4) instead.
      if ($hget($UNO.Hand,W)) {
        ; var %UNO.wild.hand = $v1
        ; msg $UNO.chan $UNO.play $iif($UNO.random == 1,$randtok(%UNO.wild.hand,32),$gettok($sorttok(%UNO.wild.hand,32,ar),1,32)) $most_cards_by_color
        msg $UNO.chan $UNO.play $gettok($sorttok($v1,32,ar),1,32) $most_cards_by_color
        ; `-> WD4 always trumps W.
        goto uno_end_turn
      }
    }
  }
  msg $UNO.chan $iif(%thisTurn == a,$UNO.draw,$UNO.pass)
  :uno_end_turn
}
alias -l uno_play_hand_a { uno_play_hand a $hget(UNO,Top) }
; `-> I have to call this separately due to the fact the top card will be incorrectly registered otherwise.
alias -l uno_set_hand {
  ; /uno_set_hand <hand ...>
  if ($hget($UNO.Hand)) { hfree $v1 }
  tokenize 32 $remove($1-,,)
  uno_add_card $*
}
alias uno_stop {
  ; /uno_stop
  .timeruno.* off
  if ($hget(UNO)) { hfree $v1 }
  if ($hget($UNO.Hand)) { hfree $v1 }
}
#UNO end

; EOF
