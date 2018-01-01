
$ ->
  
  new Vue

    el: '#game'

    data:
      score: 0
      hintDuration: 6
      hintNumber: 0
      hintScore: 0
      hints: []
      scores: null
      choices: []
      showChoices: true
      answer: null
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
        @isSigningIn in ['github','google','facebook']
      signingInWithGithub: ->
        @isSigningIn == 'github'
      signingInWithGoogle: ->
        @isSigningIn == 'google'
      signingInWithFacebook: ->
        @isSigningIn == 'facebook'
      gameHost: ->
        @game and @game.hostId == @user.uid
      gameOpen: ->
        @game and @game.status == 'open'
      gameStarting: ->
        @game and @game.status == 'starting'
      gamePlaying: -> 
        @game and @game.status == 'playing'
      gameOver: ->
        @game and @game.status == 'over'
        
    watch:
      isSigningIn: (yesOrNo) ->
        localStorage.setItem( 'isSigningIn', yesOrNo )
      countdown: ->
        if @countdown < 0
          clearInterval(@timer)
          @playGame()
      hintNumber: ->
        if @hintNumber > 3
          clearInterval(@hintTimer)
          clearInterval(@scoreTimer)
          @hintScore = 0

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
        @firestore().collection('games').where('status', '==', 'open').onSnapshot (docs) =>
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
      githubSignIn: (event) ->
        @isSigningIn = 'github'
        provider = new firebase.auth.GithubAuthProvider()
        console.log provider
        firebase.auth().signInWithRedirect( provider )

      # Sign in a user with Github
      googleSignIn: (event) ->
        @isSigningIn = 'google'
        provider = new firebase.auth.GoogleAuthProvider()
        console.log provider
        firebase.auth().signInWithRedirect( provider )

      # Sign in a user with Github
      facebookSignIn: (event) ->
        @isSigningIn = 'facebook'
        provider = new firebase.auth.FacebookAuthProvider()
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
        genre = button.text()
        @firestore().collection('games').add
          hostId: @user.uid
          photoURL: @user.photoURL
          genre: genre
          genreId: button.data('genre-id')
          status: 'open'
        .then (game) =>
          @firestore().collection('users').doc(@user.uid).update
            gameId: game.id
        console.log "Creating #{genre} game"
        
      joinGame: (event) ->
        gameId = $(event.target).closest('button').data('game-id')
        @firestore().collection('users').doc(@user.uid).update
          gameId: gameId
        .catch (error) =>
          console.log 'error joining game'
          
      leaveGame: (event) ->
        @firestore().collection('users').doc(@user.uid).update
          gameId: null
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
            if @game.status == 'starting'
              @startCountdown(5)
            @players.forEach (player) =>
              @game.scores = {} unless @game.scores?
              player.answered = @game.scores[player.uid]
          else
            @firestore().collection('users').doc(@user.uid).update
              gameId: null
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
        return unless @gameHost?
        gameId = @user.gameId
        @firestore().collection('games').doc( gameId ).delete().then =>
          console.log "Game #{gameId} deleted by #{@user.displayName}."
          @watchGames()
        .catch (error) =>
          console.log error
          
      startCountdown: (seconds) ->
        @countdown = seconds
        @timer = setInterval =>
          @countdown = @countdown - 1
        , 1000
          
      # start a game
      startGame: (event) ->
        return unless @gameHost?
        @firestore().collection('games').doc( @game.id ).update
          status: 'starting'
        .then =>
          console.log "game #{@game.id} set to starting"
        .catch (error) =>
          console.log 'error setting game status to starting'
          
      # play the game
      playGame: ->
        @showChoices = true
        @firestore().collection('games').doc( @game.id ).update
          status: 'playing'
        .then =>
          @watchTrivia( @game.id )
          console.log "game #{@game.id} set to playing"
        .catch (error) =>
          console.log 'error setting game status to playing'
          console.log error
          
      # end the game locally for the user
      endGame: ->
        @game.status = 'over'
          
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
              
            @answer = doc.data().answer
            
            @showHints()
            
      showHints: ->
        @hintScore = @hintDuration*10*@hints.length
        
        clearInterval(@scoreTimer)
        @scoreTimer = setInterval =>
          @hintScore = @hintScore - 1
        , 100
        
        clearInterval(@hintTimer)
        @hintNumber = 0
        @hintTimer = setInterval =>
          @hintNumber = @hintNumber + 1
        , @hintDuration*1000
        
      selectAnswer: (event) ->
        button = $(event.target)
        answer = button.text()
        score = if answer==@answer then @hintScore else 0
        @showChoices = false
        axios.post '/score', 
          gameId: @user.gameId
          uid: @user.uid,
          score: score
        .then (res) ->
          console.log res
        .catch (error) ->
          console.log error
            
        
        # sort players by score left to right
        # show movie poster for answer
        # store totalScore for players
        # store # of wins
        # store # games played for all
        # create /profile page
        #  -> show games played
        #  -> show total wins
        