
$ ->
  
  new Vue

    el: '#game'

    data:
      genres: []
      games: []
      user: undefined
      game: undefined
      players: []
      isSigningIn: localStorage.getItem('isSigningIn')

    created: ->
      @initFirebase()
      @watchAuth()

    computed:
      authenticated: ->
        @user
      playing: ->
        @user && @user.gameId?
      signingIn: ->
        @isSigningIn == 'yes'
      canStartGame: ->
        @game and @game.hostId == @user.uid && @game.status == 'open'
        
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
            @createUser( user )
            @watchGames()
            @getGenres()
          else
            @removeUser()

      # Watch changes to firebase games
      watchGames: ->
        @firestore().collection('games').onSnapshot (docs) =>
          @games.length = 0
          docs.forEach (doc) =>
            data = doc.data() 
            data['id'] = doc.id
            @games.push data
        , (error) ->
          console.log 'stopped listening to games'
          
      # Stop watching changes to all games
      ignoreGames: ->
        @firestore().collection('games').onSnapshot () -> {}

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

      createUser: (user) ->
        @firestore().collection("users").doc(user.uid).set
          uid: user.uid
          displayName: user.displayName
          email: user.email
          photoURL: user.photoURL
          lastLoginAt: new Date(),
          { merge: true }
        .then =>
          console.log "#{user.displayName} is logged in."
          @watchUser(user.uid)
        .catch (error) =>
          console.error "Error writing document: #{error}"

      # Watch changes to this user
      watchUser: (uid) ->
        @firestore().collection('users').doc(uid).onSnapshot (doc) =>
          if doc.exists
            console.log 'user modified'
            @user = doc.data()
            console.log "gameId is #{@user.gameId}"
            @watchGame(@user.gameId) if @user.gameId?
          else
            @removeUser()
          console.table [@user]
        , (error) ->
          console.log "stopped listening to user"

      removeUser: ->
        @user = undefined
        @isSigningIn = 'no'
        console.log "No user logged in."

      createGame: (event) ->
        genre = $(event.target).text()
        @firestore().collection('games').add
          hostId: @user.uid
          photoURL: @user.photoURL
          genre: genre
          status: 'open'
        .then (game) =>
          console.log game
          @ignoreGames()
          @watchGame( game.id )
          @firestore().collection('users').doc(@user.uid).set
            gameId: game.id, { merge: true }
        console.log "Creating #{genre} game"
        
      joinGame: (event) ->
        gameId = $(event.target).data('game-id')
        @firestore().collection('users').doc(@user.uid).set
          gameId: gameId,
          { merge: true}
        .then =>
          @ignoreGames()
          @watchGame( gameId )
        .catch (error) =>
          console.log 'error joining game'
          
      watchGame: (gameId) ->
        # Watch changes to this game.
        @firestore().collection('games').doc(gameId).onSnapshot (doc) =>
          @game = doc.data() if doc.exists
          console.log "watching game #{@game.genre}"
        , (error) ->
          console.log "stopped listening to game"
          
        # Watch players in this Game
        @firestore().collection('users').where("gameId", "==", gameId).onSnapshot (docs) =>
          @players.length = 0
          console.log 'players changed'
          docs.forEach (doc) =>
            @players.push doc.data()
        , (error) ->
          console.log 'stopped listening to players'
        
      # remove this game and start watching all games again.
      deleteGame: (event) ->
        gameId = @user.gameId
        @firestore().collection('games').doc( gameId ).delete().then =>
          @firestore().collection('users').doc(@user.uid).set
            gameId: null, { merge: true }
          console.log "Game #{gameId} deleted by #{@user.displayName}."
          @watchGames()
        .catch (error) =>
          console.log error