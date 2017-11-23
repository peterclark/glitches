$ ->
  
  new Vue

    el: '#game'

    data:
      genres: []
      games: []
      user: undefined
      isSigningIn: localStorage.getItem('isSigningIn')

    created: ->
      @initFirebase()
      @watchAuth()

    computed:
      authenticated: ->
        @user
      playing: ->
        false
      signingIn: ->
        @isSigningIn=='yes'
        
    watch:
      isSigningIn: (yesOrNo) ->
        localStorage.setItem( 'isSigningIn', yesOrNo )

    methods:
      # Initialize Firebase Database
      initFirebase: ->
        firebase.initializeApp( @firebaseConfig() )

      firestore: ->
        firebase.firestore()

      firebaseConfig: ->
        apiKey: "AIzaSyAMzN83nuL4FC8ThBy9Jyg8CqebMA4FSMk"
        authDomain: "peter-cd63b.firebaseapp.com"
        databaseURL: "https://peter-cd63b.firebaseio.com"
        projectId: "peter-cd63b"
        storageBucket: "peter-cd63b.appspot.com"
        messagingSenderId: "341628290433"

      # Watch for firebase authentication
      watchAuth: ->
        firebase.auth().onAuthStateChanged (user) =>
          if user
            @addUser( user )
            @watchGames()
            @getGenres()
          else
            @removeUser()

      # Watch changes to firebase games
      watchGames: ->
        @firestore().collection('games').onSnapshot (docs) =>
          @games.length = 0
          docs.forEach (doc) =>
            @games.push doc.data()
        , (error) ->
          console.log 'stopped listening to games'

        # @firestore().collection('games').onSnapshot (snapshot) ->
        #   snapshot.docChanges.forEach (change) ->
        #     if change.type == 'added'
        #       @games.push change.doc.data()
        #     else if change.type == 'modified'
        #       console.log 'modified'
        #     else if change.type == 'removed'
        #       doc = change.doc.data()

      # Sign in a user with Github
      signIn: (event) ->
        @isSigningIn = 'yes'
        provider = new firebase.auth.GithubAuthProvider()
        firebase.auth().signInWithRedirect( provider )

      # Logout a user
      signOut: (event) ->
        firebase.auth().signOut()

      # Get genres from server
      getGenres: ->
        axios.get('/genres').then (response) =>
          @genres.length = 0
          response.data.forEach (genre) =>
            @genres.push genre

      addUser: (user) ->
        @firestore().collection("users").doc(user.uid).set
          displayName: user.displayName,
          email: user.email,
          photoURL: user.photoURL
          lastLoginAt: new Date()
        .then =>
          @user = user
          console.log "#{user.displayName} is logged in."
        .catch (error) =>
          console.error "Error writing document: #{error}"

      removeUser: ->
        @user = undefined
        @isSigningIn = 'no'
        console.log "No user logged in."

      createGame: (event) ->
        genre = $(event.target).text()
        @firestore().collection('games').add
          host: @user.uid
          photoURL: @user.photoURL
          genre: genre
        .then (game) =>
          @firestore().collection('users').doc(@user.uid).set
            game_id: game.id, { merge: true }
        console.log "Creating #{genre} game"