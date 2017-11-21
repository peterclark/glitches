class window.Game

  constructor: ->
  
    @data = {
      genres: []
      games: []
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
        computed:
          playing: ->
            false
              
        
window.game = new Game