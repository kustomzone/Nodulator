require! {
  fs
  repl
  path
  \prelude-ls
  '\../' : N
  livescript
  \../src/Modules/Nodulator-Account : N-Account
}

module.exports = (configPath, resPath)->


  global import prelude-ls


  if not configPath or not resPath
    console.log 'Usage: ./Console pathToConfig pathToResources'
    process.exit()

  rootPath = path.resolve '.'


  wrapper = (cmd, done) ->
    if cmd.length is 1
      cmd = cmd.replace /\n/g, 'null;'

    util = require 'util'

    varName = ''
    if cmd.match /\=/g
      varName := cmd.split ' =' .0

    res = eval livescript.compile cmd, bare: true, header: false colors: true

    if res?
      if res.then?

        res.fail ~>
          @[varName] = it
          done null, it

        res.then ~>
          if is-type \Array it
            it |> each (.inspect = -> @ToJSON!)
            # it.inspect = -> _(@).invoke('ToJSON')
            @[varName] = it
            done null, it
          else
            it.inspect = -> @ToJSON!
            @[varName] = it
            done null, it

      else
        @[varName] = res
        done null, res

    else
      @[varName] = res
      done null, res

  inst = repl.start do
    prompt: 'N > '
    useGlobal: true
    input: process.stdin
    output: process.stdout
    eval: (cmd, context, filename, callback) ->
      wrapper.call context, cmd, callback

  try config = require rootPath + \/ + configPath

  N.Console()
  N.Config config || {}
  N.Use N-Account
  # N.AccountResource = N~Resource

  inst.context.N = N

  fetch-resources = (path) ->
    files = fs.readdirSync path

    res = {}
    for file in files
      stat = fs.statSync path + '/' + file
      if stat.isDirectory()
        res := _(res).extend fetch-resources path + '/' +  file
      else
        if file[0] isnt '.' and file.split('.')[0] isnt \index and file.split('.')[1] in ['coffee', 'ls', 'js']
          res[file.split('.')[0]] = path + \/ + file

    res

  fetch-resources resPath
    |> obj-to-pairs
    |> map -> try require rootPath + \/ + it.1
    |> each -> inst.context[capitalize it._table.name] = it if it?._table?
  # N.resources
  #   |> each ->

      # if res?._table?