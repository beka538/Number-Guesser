#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

RANDOM_NUMBER=$(( RANDOM % 1001 ))
#echo $RANDOM_NUMBER

NUMBER_OF_GUESSES=0

START_GAME() {
  echo "Enter your username: "
  read USERNAME_INPUT

  USERNAME=$($PSQL "SELECT username FROM players WHERE username='$USERNAME_INPUT'")

  # if username does not exist
  if [[ "$USERNAME" != "$USERNAME_INPUT" ]]
  then
    #add player to database
    USERNAME=$USERNAME_INPUT
    INSERT_USERNAME_RESULT=$($PSQL "INSERT INTO players(username, games_played, best_game) VALUES('$USERNAME', 0, 0)")
    
    echo "Welcome, $USERNAME! It looks like this is your first time here."
  else
    # get player data
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM players WHERE username='$USERNAME'")
    BEST_GAME=$($PSQL "SELECT best_game FROM players WHERE username='$USERNAME'")
    
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi
  
  # start number guessing game
  NUMBER_GUESS "Guess the secret number between 1 and 1000: "
  NUMBER_OF_GUESSES=$?

  # increment games played
  (( GAMES_PLAYED++ ))

  # if player beat guess record or first game  
  if [[ $NUMBER_OF_GUESSES < $BEST_GAME || $BEST_GAME==0 ]]
  then
    # update best game
    BEST_GAME=$NUMBER_OF_GUESSES
  fi
  # update player database
  UPDATE_PLAYER $USERNAME $GAMES_PLAYED $BEST_GAME
}

NUMBER_GUESS() {
  GUESS_MESSAGE=$1
  echo "$GUESS_MESSAGE"
  read NUMBER_GUESS

  # add to number of guesses
  (( NUMBER_OF_GUESSES++ ))
  
  # if not an integer or null
  if ! [[ $NUMBER_GUESS =~ ^[0-9]*+$ ]]
  then
    NUMBER_GUESS "That is not an integer, guess again: "
  elif [[ -z $NUMBER_GUESS ]]
  then
    echo "You entered nothing!"
    return
  else
      #echo "Number of guesses: $NUMBER_OF_GUESSES"
    # if guess is higher than number
    if [[ $NUMBER_GUESS -gt $RANDOM_NUMBER ]]
    then
      # guess again
      NUMBER_GUESS "It's lower than that, guess again: "
    # if guess is lower than number
    elif [[ $NUMBER_GUESS -lt $RANDOM_NUMBER ]]
    then
      # guess again
      NUMBER_GUESS "It's higher than that, guess again: "
    # if guess is correct
    else
      echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"
      return $NUMBER_OF_GUESSES
    fi
  fi

}

UPDATE_PLAYER() {
  UPDATE_PLAYER_RESULT=$($PSQL "UPDATE players SET games_played=$2, best_game=$3 WHERE username='$1'")
}

START_GAME
