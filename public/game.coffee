class window.Game

  constructor: ->
  
    @data = {
      genres: []
      user: undefined
      authenticated: false
    }

    axios.get('/genres').then (response) =>
      @data.genres.length = 0
      response.data.forEach (genre) =>
        @data.genres.push genre
  
    @vue =   
      new Vue
        el: '#game'
        data: @data 
        
window.game = new Game