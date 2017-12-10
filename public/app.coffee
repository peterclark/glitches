
$ ->
  
  new Vue

    el: '#game'

    data:
      hintNumber: 0
      hints: []
      choices: []
      genres: []
      games: []
      user: null
      game: null
      players: []
      countdown: 5
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
      canControlGame: ->
        @game and @game.status == 'open' and @game.hostId == @user.uid 
      canLeaveGame: ->
        @game and @game.status == 'open'
      gameStarting: ->
        @game and @game.status == 'starting'
      gamePlaying: -> 
        @game and @game.status == 'playing'
        
    watch:
      isSigningIn: (yesOrNo) ->
        localStorage.setItem( 'isSigningIn', yesOrNo )
      countdown: ->
        if @countdown < 0
          clearInterval(@timer)
          @playGame()

    methods:
      # Initialize Firebase Database
      initFirebase: ->
        firebase.initializeApp( @firebaseConfig() )

      firestore: ->
        firebase.firestore()

      firebaseConfig: ->
        apiKey: "AIzaSyBiL1Ikw4zCZ-0T3YxmuWPXKZDxAu4UuRo"
        authDomain: "trivia-17e61.firebaseapp.com"
        databaseURL: "https://trivia-17e61.firebaseio.com"
        projectId: "trivia-17e61"

      # Watch for firebase authentication
      watchAuth: ->
        firebase.auth().onAuthStateChanged (user) =>
          if user
            @watchGames()
            @createUser( user )
            @getGenres()
          else
            @removeUser()

      # Watch changes to open firebase games
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
        console.log 'stopped listenting to all games'
        @firestore().collection('games').onSnapshot () -> {}

      # Sign in a user with Github
      signIn: (event) ->
        @isSigningIn = 'yes'
        provider = new firebase.auth.GithubAuthProvider()
        console.log provider
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
        console.log user.uid
        @firestore().collection("users").doc(user.uid).set
          uid: user.uid
          displayName: user.displayName
          email: user.email
          photoURL: user.photoURL
          lastLoginAt: new Date(),
          { merge: true }
        .then =>
          @watchUser(user.uid)
        .catch (error) =>
          console.log "Error writing document: #{error}"

      # Watch changes to this user
      watchUser: (uid) ->
        @firestore().collection('users').doc(uid).onSnapshot (doc) =>
          if doc.exists
            console.log 'user modified'
            gameId = doc.data().gameId
            if gameId?
              @game = @games.find (game) -> game.id == gameId
              @watchGame( gameId )
              @watchTrivia( gameId )
            else
              @watchGames()
            @user = doc.data()
          else
            @removeUser()
          console.table [@user]
        , (error) ->
          console.log "stopped listening to user"

      removeUser: ->
        @user = null
        @isSigningIn = 'no'
        console.log "No user logged in."

      createGame: (event) ->
        button = $(event.target)
        @firestore().collection('games').add
          hostId: @user.uid
          photoURL: @user.photoURL
          genre: button.text()
          genreId: button.data('genre-id')
          status: 'open'
        .then (game) =>
          @firestore().collection('users').doc(@user.uid).set
            gameId: game.id, { merge: true }
        console.log "Creating #{genre} game"
        
      joinGame: (event) ->
        gameId = $(event.target).closest('button').data('game-id')
        @firestore().collection('users').doc(@user.uid).set
          gameId: gameId, { merge: true }
        .catch (error) =>
          console.log 'error joining game'
          
      leaveGame: (event) ->
        @firestore().collection('users').doc(@user.uid).set
          gameId: null, { merge: true }
        .catch (error) =>
          console.log 'error leaving game'
          
      watchGame: (gameId) ->
        # Watch changes to this game.
        console.log "watching game #{gameId}"
        @ignoreGames()
        @firestore().collection('games').doc(gameId).onSnapshot (doc) =>
          console.log "Game #{gameId} changed"
          if doc.exists
            data = doc.data()
            data.id = doc.id
            @game = data
            @startCountdown(5) if @game.status == 'starting'
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
          
      startCountdown: (seconds) ->
        @coundown = seconds
        @timer = setInterval =>
          @countdown = @countdown - 1
        , 1000
          
      # start a game
      startGame: (event) ->
        return unless @canControlGame?
        @firestore().collection('games').doc( @game.id ).set
          status: 'starting', { merge: true }
        .then =>
          console.log "game #{@game.id} set to starting"
        .catch (error) =>
          console.log 'error setting game status to starting'
          
      # play the game
      playGame: ->
        @firestore().collection('games').doc( @game.id ).set
          status: 'playing', { merge: true }
        .then =>
          @watchTrivia( @game.id )
          console.log "game #{@game.id} set to playing"
        .catch (error) =>
          console.log 'error setting game status to playing'
          console.log error
          
      watchTrivia: (gameId) ->
        @firestore().collection('trivia').doc( gameId ).onSnapshot (doc) =>
          if doc.exists
            
            @hints.length = 0
            hints = doc.data().hints
            hints.forEach (hint) =>
              @hints.push hint
              
            @choices.length = 0
            choices = doc.data().choices
            choices.forEach (choice) =>
              @choices.push choice
          
        # build movie description:
        #  => year (3 sec delay)
        #  => main actor (3 sec delay)
        #  => tagline
        #  => overview (1st 100 characters)
        #  => poster image
        # show winner or noboby
        # show answer
        # loop for 4 more questions
        # then show scores of top 3 in reverse order
        # store win for winner
        # store # games for all
        # back to listing of games