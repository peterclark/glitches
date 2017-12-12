axios      = require 'axios'
underscore = require 'underscore'

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
      movies = (new Movie(movie) for movie in response.data.results)
      underscore.shuffle movies
    .catch (error) ->
      console.log error
    
module.exports = new MovieDB( process.env.MOVIEDB_API_KEY ) 


class Movie
  
  constructor: (data) ->
    @id            = data.id
    @title         = data.title
    @posterPath    = data.poster_path
    @backdropPath  = data.backdrop_path
    @overview      = data.overview
    @releaseDate   = data.release_date
    
  backdropImageURL: ->
    "https://image.tmdb.org/t/p/w300" + @backdropPath
    
  backdropImageTag: ->
    "<img src='#{@backdropImageURL()}'>"
    
  posterImageURL: ->
    "https://image.tmdb.org/t/p/w92" + @posterPath
    
  posterImageTag: ->
    "<img src='#{@posterImageURL()}'>"
    
  releaseYear: ->
    date = new Date(@releaseDate)
    date.getFullYear()
    
  shortOverview: ->
    @overview.split(' ')[0..15].join(' ') + '...'