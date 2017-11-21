axios = require 'axios'

class MovieDB
  
  constructor: (api_key) ->
    
    @api_key = api_key
    @base_url = "https://api.themoviedb.org/3"
    @language = "language=en-US"
    
  endpoint: (path) ->
    "#{@base_url}#{path}?api_key=#{@api_key}&#{@language}"
    
  genres: () ->
    genre_url = @.endpoint('/genre/movie/list')
    axios.get( genre_url ).then (response) ->
      response.data.genres
    .catch (error) ->
      console.log error
    
module.exports = new MovieDB( process.env.MOVIEDB_API_KEY ) 