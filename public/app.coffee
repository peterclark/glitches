
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
      genres: []
      games: []
      user: null
      game: null
      players: []
      profile: false
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
        @isSigningIn in ['github.com','google.com','facebook.com']
      signingInWithGithub: ->
        @isSigningIn == 'github.com'
      signingInWithGoogle: ->
        @isSigningIn == 'google.com'
      signingInWithFacebook: ->
        @isSigningIn == 'facebook.com'
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
      showProfile: ->
        @user and @profile
      showChoices: ->
        !@game.scores[@user.uid]?
        
        
    watch:
      isSigningIn: (yesOrNo) ->
        localStorage.setItem( 'isSigningIn', yesOrNo )
      hintNumber: ->
        if @hintNumber > 3
          console.log 'clearing hint and score timers'
          clearInterval(@hintTimer)
          clearInterval(@scoreTimer)
          @hintScore = 0

    methods:
      # Initialize Firebase Database
      initFirebase: ->
        firebase.initializeApp( @myFirebaseConfig() )

      firestore: ->
        firebase.firestore()

      myFirebaseConfig: ->
        apiKey: "AIzaSyBiL1Ikw4zCZ-0T3YxmuWPXKZDxAu4UuRo"
        authDomain: "trivia-17e61.firebaseapp.com"
        databaseURL: "https://trivia-17e61.firebaseio.com"
        projectId: "trivia-17e61"

      grFirebaseConfig: ->
        apiKey: "AIzaSyAMzN83nuL4FC8ThBy9Jyg8CqebMA4FSMk"
        authDomain: "peter-cd63b.firebaseapp.com"
        databaseURL: "https://peter-cd63b.firebaseio.com"
        projectId: "peter-cd63b"

      # Watch for firebase authentication
      watchAuth: ->
        firebase.auth().getRedirectResult()
        .then (result) ->
          console.log "Successful sign in for #{result.user.displayName}"
        .catch (error) =>
          if error.code == 'auth/account-exists-with-different-credential'
            email = error.email
            cred = error.credential
            firebase.auth().fetchProvidersForEmail(email).then (providerIds) =>
              @signInAndLink( providerIds[0], cred )
              
        firebase.auth().onAuthStateChanged (user) =>
          if user
            @watchGames()
            @createUser( user )
            @getGenres()
          else
            @removeUser()
            
      toggleProfile: ->
        @profile = !@profile

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
        @isSigningIn = 'github.com'
        provider = new firebase.auth.GithubAuthProvider()
        @signInWithProvider( provider )

      # Sign in a user with Google
      googleSignIn: (event) ->
        @isSigningIn = 'google.com'
        provider = new firebase.auth.GoogleAuthProvider()
        @signInWithProvider( provider )

      # Sign in a user with Facebook
      facebookSignIn: (event) ->
        @isSigningIn = 'facebook.com'
        provider = new firebase.auth.FacebookAuthProvider()
        @signInWithProvider( provider )
        
      signInWithProvider: (provider) ->
        console.log "Attempting to sign in with #{provider.providerId}"
        firebase.auth().signInWithRedirect( provider )
        
      signInAndLink: (providerId, cred) ->
        console.table cred
        # switch providerId
        #   when 'github.com' then @githubSignIn()
        #   when 'facebook.com' then @facebookSignIn()
        #   when 'google.com' then @googleSignIn()
        #   else
        #     console.log "can't login with provderId = #{providerId}"

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
          createdAt: new Date()
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
            @players.forEach (player) =>
              @game.scores = {} unless @game.scores?
              if @game.scores[player.uid]?
                score = @game.scores[player.uid]
                console.log "score is #{score}"
                player.answered = score
            if @gameOver
              console.log 'clearing choices and hints'
              @choices = []
              @hints = []
          else
            @firestore().collection('users').doc(@user.uid).update
              gameId: null
        , (error) ->
          console.log "stopped listening to game"
          
        # Watch players in this Game
        @firestore().collection('users').where("gameId", "==", gameId).onSnapshot (docs) =>
          return if @gameOver # so we don't overwrite their scores
          @players.length = 0
          docs.forEach (doc) =>
            console.log "player #{doc.data().displayName} updated"
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
          
      # play the game
      playGame: ->
        @firestore().collection('games').doc( @game.id ).update
          status: 'playing'
          startedAt: new Date()
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
        axios.post '/score', 
          uid: @user.uid
          gameId: @user.gameId
          answer: button.text()
        .then (res) ->
          console.log res
        .catch (error) ->
          console.log error
        