firebaseAdmin   = require 'firebase-admin' 
serviceAccount  = require './firebase.json' 
moviedb         = require './moviedb'
underscore      = require 'underscore'
moment          = require 'moment'
timer           = require 'moment-timer'

class Firestore
  
  constructor: () ->
    firebaseAdmin.initializeApp
      credential: firebaseAdmin.credential.cert(serviceAccount)
    @database = firebaseAdmin.firestore()
    
  watchGames: ->
    @database.collection('games').where("status", "==", "playing").onSnapshot (snapshot) =>
      snapshot.docChanges.forEach (change) =>
        if change.type == 'added'
          console.log 'game is now playing'
          @addTriviaToGame(change.doc)
        else if change.type == 'removed'
          console.log 'game is now removed'
          @removeTriviaForGame( change.doc )
          
  addTriviaToGame: (game) ->
    moviedb.getMovies(game.data().genreId).then (movies) =>
      answer = movies[0]
      movies = underscore.shuffle movies[0..3]
      console.log 'adding trivia'
      @database.collection('trivia').doc(game.id).set
        hints: [
          answer.releasedIn(),
          answer.shortOverview(),
          answer.backdropImageTag(),
          answer.posterImageTag()
        ]
        choices: (movie.title for movie in movies)
        answer: answer.title
      .then =>
        @endGame(game.id)
        
  
  removeTriviaForGame: (game) ->
    console.log 'removing trivia'
    @database.collection('trivia').doc(game.id).delete().then ->
      console.log "deleted trivia for game #{game.id}"
      
  registerScoreForUser: (uid, score, gameId) ->
    console.log 'registering score'
    @database.collection('games').doc(gameId).update
      "scores.#{uid}": score
      
  endGame: (gameId) ->
    setTimeout =>
      @database.collection('games').doc(gameId).update( status: 'over' )
      console.log "Ending game #{gameId}"
    , 24000

module.exports = new Firestore