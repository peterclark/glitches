class window.Database
  
  constructor: ->
    config = {
      apiKey: "AIzaSyAMzN83nuL4FC8ThBy9Jyg8CqebMA4FSMk",
      authDomain: "peter-cd63b.firebaseapp.com",
      databaseURL: "https://peter-cd63b.firebaseio.com",
      projectId: "peter-cd63b",
      storageBucket: "peter-cd63b.appspot.com",
      messagingSenderId: "341628290433"
    }
    firebase.initializeApp(config)
  
    @firestore = firebase.firestore()
    @watchGames()
    
  addUser: (user) ->
    @firestore.collection("users").doc(user.uid).set
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL
    .then ->
      console.log "#{user.displayName} written to users database."
    .catch (error) ->
      console.error "Error writing document: #{error}"
      
  addGame: (user, genre) ->
    @firestore.collection('games').add
      host: user.uid
      photoURL: user.photoURL
      genre: genre
      
  watchGames: ->
    @firestore.collection('games').onSnapshot (docs) ->
      game.data.games.length = 0
      docs.forEach (doc) ->
        game.data.games.push doc.data()
    # @firestore.collection('games').onSnapshot (snapshot) ->
    #   snapshot.docChanges.forEach (change) ->
    #     if change.type == 'added'
    #       game.data.games.push change.doc.data()
    #     else if change.type == 'modified'
    #       console.log 'modified'
    #     else if change.type == 'removed'
    #       doc = change.doc.data()
    
window.database = new Database