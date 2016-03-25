_ = require 'underscore'
fs = require 'fs'
path = require 'path'
jade = require 'jade'
cookieParser = require 'cookie-parser'
coffeeMiddleware = require 'coffee-middleware'
livescriptMiddleware = require 'livescript-middleware'
grunt = require 'grunt'

NModule = require \../NModule

class NAssets extends NModule

  list: {}
  views: {}
  extendedRun: []
  extendedRender: []
  compiled: false
  engine: jade
  name: 'NAssets'

  defaultConfig:
    sites:
      app:
        path: '/client'
        public:
          '/img': ''
          js: []
          css: []

    viewRoot: 'client'
    engine: 'jade' #FIXME: no other possible engine
    minified: false

  Init: ->
    N.assets = @

    for site, obj of @config.sites
      @AddFolders do
        "#{@config.sites[site].path}/public/#{site}.min.js" : @config.sites[site].public.js
        "#{@config.sites[site].path}/public/#{site}.min.css" : @config.sites[site].public.css

    thus = this

    # To be called last
    N.Run = ->

      for process in thus.extendedRun
        process!

      # FIXME: ugly fix for favicon
      @app.get '/favicon.ico', (req, res) ~>
        res.status(200).end()

      @app.get '*', (req, res) ~>
        @Render req, res

    N.Render = (req, res) ->

      for process in thus.extendedRender
        if not process req, res
          return

      res.render 'index'

    N.ExtendBeforeRender = (process) ~>
      @extendedRender.unshift process

    N.ExtendAfterRender = (process) ~>
      @extendedRender.push process

    N.ExtendBeforeRun = (process) ~>
      @extendedRun.unshift process

    N.ExtendAfterRun = (process) ~>
      @extendedRun.push process

    N.ExtendBeforeRun ~>
      @_Serve()

    N.Route._InitServer!

  PostConfig: ->
    N.Run!

  _InitGrunt: ->
    grunt.task.init = ->

    coffee = {}
    for name, files of @list
      if name.split('/')[name.split('/').length - 1].split('.')[2] is 'js'
        name_ = name[1 to].replace /\.min/g, '.coffee'
        coffee[name_] = _(files).filter (item) -> item.split('.')[1] is 'coffee'
        coffee[name_] = _(coffee[name_]).map (item) -> item[1 to]*''

    minifiedJs = {}
    for name, files of @list
      if name.split('/')[name.split('/').length - 1].split('.')[2] is 'js'
        coffeeName = name[1 to]*'' .replace /\.min/g, '.coffee'
        name_ = name[1 to]*''
        minifiedJs[name_] = _(files).filter (item) -> item.split('.')[item.split('.').length - 1] is 'js'
        minifiedJs[name_] = _(minifiedJs[name_]).map (item) -> item[1 to]*''
        minifiedJs[name_].push coffeeName

    minifiedCss = {}
    for name, files of @list
      if name.split('/')[name.split('/').length - 1].split('.')[2] is 'css'
        name_ = name[1 to]*''
        minifiedCss[name_] = _(files).filter (item) -> item.split('.')[item.split('.').length - 1] is 'css'
        minifiedCss[name_] = _(minifiedCss[name_]).map (item) -> item[1 to]*''

    grunt.initConfig do
      coffee:
        compile:
          options:
            join: true
          #   bare: true
          files: coffee
      uglify:
        assets:
          options:
            # beautify: true
            mangle: false
          files: minifiedJs
      cssmin:
        assets:
          files: minifiedCss

    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-contrib-cssmin');

  _RunGrunt: ->
    grunt.tasks ['coffee', 'uglify', 'cssmin'], {}, ->
      grunt.log.ok('Done running tasks.');

  _GetFiles: (name, dirs, rec = false) ->
    console.log \wow dirs
    for dir in dirs when dir?
      console.log \Getfiles dir

      if dir[dir.length - 1] isnt '/'
        dir += '/'

      entries = fs.readdirSync path.resolve N.appRoot, '.' + dir

      files = _(entries).filter (entry) ~>
        fs.statSync(N.appRoot + dir + entry).isFile() and
          (entry.match(/\.coffee$/g) or entry.match(/\.js$/g) or entry.match(/\.css$/g))

      if rec
        folders = _(entries).filter (entry) ~>
          fs.statSync(N.appRoot + dir + entry).isDirectory() and not entry.match(/^\./g)
        folders = _(folders).map (folder) ~>
          dir + folder

        @_GetFiles name, folders, true

      files = _(files).map (file) ~>
        if file.match(/\.coffee$/g)
          dir + file
        else if file.match(/\.js$/g) or file.match(/\.css$/g)
          dir + file

      if not @list[name]
        @list[name] = files
      else
        @list[name] = @list[name].concat files

  AddFoldersRec: (list) ->
    for name, dirs of list
      @_GetFiles name, dirs, true

  AddFolders: (list) ->
    for name, dirs of list
      @_GetFiles name, dirs

  _Serve: ->

    if @config.minified
      @_InitGrunt()
      @_RunGrunt()

    @compiled = {}
    Compile = (site) ~>
      jcompile = {}
      if N.nangulator?
        jcompile = _(jcompile).extend N.nangulator.Compile()

      for name, list of @list
        site_ = name.split('/')[name.split('/').length - 1].split('.')[0]
        @compiled[site_] = jcompile[site_]() if not @compiled[site_]?

      @compiled[site]

    url_to_paths = {}
    if @config.minified
      # for site, files of @list
      #   site_ = site.split('/')[site.split('/').length - 1].split('.')[0]
      #   files_ = _(files).map (item) -> N.appRoot + item
      #   compressor.minify
      #     type: 'uglifyjs'
      #     fileIn: files_
      #     fileOut: "#{@config.sites[site_].path}/public/js/#{site_}.js"
      for site, config of @config.sites

        Compile site

    if not @config.minified

      for site, paths of @list
        if site.split('/')[site.split('/').length - 1].split('.')[2] is 'js'

          @list[site] = _(paths).map (item) ->
            if item.split('.')[1] is 'coffee'
              item.replace /\.coffee/g, '.js'
            else              item


      N.app.use coffeeMiddleware do
        src: path.resolve N.appRoot, '.'
        prefix: 'coffee'
        bare: true
        force: true

    # N.app.use minify()
    N.app.use require('connect-cachify').setup @list,
      root: path.join N.appRoot, '.'
      # root:  N.appRoot
      # url_to_paths: {'/img/': '/client/public/img'}
      production: @config.minified
      # debug: true
    console.log \TAMER
    for site, config of @config.sites
      console.log \tessur
      for destPath, origPath of @config.sites[site].public
        for p in origPath
          if p[0] is '/'
            p = '.' + p
          console.log \lol p

          N.app.use "#{destPath}",  N.express.static path.resolve N.appRoot, p

    console.log \wtf
    if not @config.minified
      N.app.use N.express.static path.resolve N.appRoot
    else
      for name, paths of @list
        siteName = name.split('/')[name.split('/').length - 1]
        site = '/' + siteName.split('.')[0] + '/' + siteName.split('.')[siteName.split('.').length - 1] + name
        console.log \Lol name
        N.app.use name,  N.express.static path.resolve N.appRoot, name[1 to]*''

    N.app.use cookieParser 'nodulator'

    N.app.set 'views', path.resolve N.appRoot, @config.viewRoot
    N.app.engine '.' + @config.engine, jade.__express
    N.app.set 'view engine', @config.engine

    N.app.use (req, res, next) ~>

      res.locals.nodulator = (site = 'app') ~>
        comp = {}
        if not @config.minified
          @compiled = {}
          comp = Compile site
        else
          comp = @compiled[site]

        comp += res.locals.cachify_js "#{@config.sites[site].path}/public/#{site}.min.js"
        comp += res.locals.cachify_css "#{@config.sites[site].path}/public/#{site}.min.css"

        if N.AccountResource?
          comp += N.AccountResource._AccountResource._InjectUser req

        comp

      next()

  AddView: (view, site = 'app') ->
    @views[site] = '' if not @views[site]?
    @views[site] += view

module.exports = NAssets
