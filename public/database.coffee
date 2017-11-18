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
    
  addUser: (user) ->
    @firestore.collection("users").doc(user.uid).set
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL
    .then ->
      console.log "#{user.displayName} written to users database."
    .catch (error) ->
      console.error "Error writing document: #{error}"
    
window.database = new Database