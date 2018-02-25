firebaseAdmin   = require 'firebase-admin' 
serviceAccount  = require './firebase.json'
grAccount       = require './greenriver.json'
moviedb         = require './moviedb'
_               = require 'underscore'

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
      movies = _.shuffle movies[0..3]
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
      "scores.#{uid}": { uid: uid, score: score }
      
  endGame: (gameId) ->
    setTimeout =>
      game = @database.collection('games').doc(gameId)
      game.update( status: 'over' )
      console.log "Ending game #{gameId}"
      @updateStats(game)
    , 24000
    
  updateStats:  (game) ->
    game.get().then (doc) =>
      if doc.exists
        winner = @winner(doc.data())
        @updateWinner(winner)
    .catch (error) ->
      console.log error
      
  winner: (game) ->
    _.max game.scores, (player) -> player.score
    
  updateWinner: (winner) ->
    console.log winner
    player = @database.collection('users').doc(winner.uid)
    player.get().then (doc) ->
      user = doc.data()
      highScore   = user.highScore || 0
      gamesPlayed = user.gamesPlayed || 0
      gamesWon    = user.gamesWon || 0
      
      highScore = 
        if winner.score > highScore 
        then winner.score 
        else highScore
          
      player.update 
        gamesPlayed: gamesPlayed + 1
        gamesWon: gamesWon + 1
        highScore: highScore
      
      
      

module.exports = new Firestore