# UNO-pseudo-AI
A script to play UNO on IRC on my behalf in a very efficient manner.

One of the IRC networks I hang out on has an IRC bot on it using the script @ http://hawkee.com/snippet/5301/

Me being me, I wrote a script to play the game on my behalf in a highly efficient manner.

Esentially, it'll avoid playing certain cards if it knows it can link them to other cards.

For example, if the top card is Red 3, and I have a Red 7, Red 5, Red DT, Yellow DT, Blue DT and Blue 9 in my hand
it'll play either Red 7 or Red 5 first simply because it knows it can Red DT->Yellow DT->Blue DT->Blue 9.
