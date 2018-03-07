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
          console.log 'game is not playing'
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
      "scores.#{uid}": score
      
  endGame: (gameId) ->
    setTimeout =>
      game = @database.collection('games').doc(gameId)
      game.update( status: 'over' )
      @updateStats(game)
    , 24000
    
  updateStats:  (game) ->
    game.get().then (doc) =>
      if doc.exists
        scores = doc.data().scores
        winner = @winner(scores)
        console.log "winner is #{winner}"
        @updatePlayer( uid, score, winner ) for uid, score of scores
      else
        console.log 'game does not exist'
    .catch (error) ->
      console.log error
      
  winner: (scores) ->
    _.max Object.keys(scores), (score) -> scores[score]
    
  updatePlayer: (uid, score, winner) ->
    console.log "updating #{uid} with #{score}"
    user = @database.collection('users').doc(uid)
    user.get().then (doc) ->
      data = doc.data()
      console.log "updating stats for #{data.displayName}"
      highScore   = data.highScore || 0
      gamesPlayed = data.gamesPlayed || 0
      gamesWon    = data.gamesWon || 0
      
      highScore = if score > highScore then score else highScore
         
      if uid == winner
        gamesWon = gamesWon + 1
          
      user.update 
        gamesPlayed: gamesPlayed + 1
        gamesWon: gamesWon
        highScore: highScore
      
      
module.exports = new Firestore