axios = require 'axios'

class MovieDB
  
  constructor: (api_key) ->
    
    @api_key = api_key
    @base_url = "https://api.themoviedb.org/3"
    
  api: ->
    'api_key=' + @api_key
    
  genre: (id) ->
    'with_genres=' + id
    
  sort: (vector) ->
    'sort_by=' + vector
    
  page: ->
    page = Math.floor(Math.random()*20) + 1
    'page=' + page
    
  shuffle: (array) ->
    array.sort -> Math.random() - 0.5
    
  genres: () ->
    genre_url = @base_url + '/genre/movie/list?' + @api() 
    axios.get( genre_url ).then (response) ->
      response.data.genres
    .catch (error) ->
      console.log error
      
  getMovies: (genreId) ->
    movie_url = @base_url + 
      '/discover/movie' + 
      '?' + @genre(genreId) + 
      '&' + @sort('popularity.desc') + 
      '&' + @page() +
      '&' + @api()
    axios.get( movie_url ).then (response) =>
      @shuffle response.data.results
    .catch (error) ->
      console.log error
    
module.exports = new MovieDB( process.env.MOVIEDB_API_KEY ) 