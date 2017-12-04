# firebaseAdmin   = require 'firebase-admin' 
# serviceAccount  = require './firebase.json' 
# moviedb         = require './moviedb'

# class Firestore
  
#   constructor: ->
#     firebaseAdmin.initializeApp
#       credential: firebaseAdmin.credential.cert(serviceAccount)
      
#   database: ->
#     firebaseAdmin.firestore()
    
#   watchGames: ->
#     firestore.collection('games').onSnapshot (games) ->
#       pushQuestionTo game for game in games when game.data().status is 'starting'
                
#   pushQuestionTo: (game) ->
#     game = game.data()
#     moviedb.getMovies( game.genreId ).then (movies) ->
#       movies.forEach (movie) ->
#         console.log movie.title
#         firestore.collection('questions').add
#           id: movie.id
#           title: movie.title
#           release_date: movie.release_date
#           overview: movie.review
#           gameId: game.id
#         .then (question) =>
#           console.log "Created question for #{movie.title}"
    

# module.exports = (new Firestore).database()