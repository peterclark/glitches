express = require 'express'
app = express()

coffeeMiddleware  = require 'coffee-middleware'
engines           = require 'consolidate'
bodyParser        = require 'body-parser'
stylish           = require 'stylish'
autoprefixer      = require 'autoprefixer-stylus'
axios             = require 'axios'
moviedb           = require './moviedb'

moviedb.genres().then (genres) -> 
  app.set 'genres', genres

app.use(express.static('assets'))

# sets up pug
app.engine('pug', engines.pug)

# sets up coffeescript support
app.use coffeeMiddleware
  bare: true
  src: "public"
require('coffee-script/register')

# body parser
app.use bodyParser.urlencoded
  extended: false
app.use bodyParser.json()
app.use bodyParser.text()

# sets up stylus and autoprefixer
app.use stylish
  src: __dirname + '/public'
  setup: (renderer) ->
    renderer.use autoprefixer()
  watchCallback: (error, filename) ->
    if error
      console.log error
    else
      console.log "#{filename} compiled to css"

# set server port and start listening
PORT = 3000
app.listen PORT, ->
  console.log "Your app is running on #{PORT}"
            
# ROUTES
app.get '/', (req, res) ->
  res.render 'index.pug'

app.get '/genres', (req, res) ->
  res.json app.get('genres')