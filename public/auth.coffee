$ ->
  
  # Use github authentication
  $(document).on 'click', '.login-btn', (e) ->
    $('.fa-github').toggleClass('hidden-xs-up')
    $('.fa-spinner').toggleClass('hidden-xs-up')
    localStorage.setItem 'userIsLoggingIn', 'yes'
    provider = new firebase.auth.GithubAuthProvider()
    firebase.auth().signInWithRedirect( provider )
  
  # Logout the user
  $(document).on 'click', '.logout-btn', (e) ->
    firebase.auth().signOut()
    