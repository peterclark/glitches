$ ->
  # users = []
  # firestore.collection('users').onSnapshot (docs) ->
  #   users.length = 0
  #   docs.forEach (doc) ->
  #     users.push doc.data()
      
  firebase.auth().onAuthStateChanged (user) ->
    if user
      database.addUser user
      game.data.user = user
      game.data.authenticated  = true
      console.log "#{user.displayName} is logged in."
    else
      game.data.authenticated = false
      localStorage.setItem 'userIsLoggingIn', 'no'
      console.log "No user logged in."
      
  loggingIn = localStorage.getItem 'userIsLoggingIn'
  
  if loggingIn == 'yes'
    $('.fa-github').addClass('hidden-xs-up')
    $('.fa-spinner').removeClass('hidden-xs-up')
  else
    $('.fa-github').removeClass('hidden-xs-up')
    $('.fa-spinner').addClass('hidden-xs-up')
