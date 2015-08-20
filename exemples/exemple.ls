_ = require 'underscore'
Nodulator = require '../'
request = require 'superagent'
async = require 'async'

weaponConfig =
  schema:
    hitPoints: 'int'

Weapons = Nodulator.Resource 'weapon', Nodulator.Route.MultiRoute, weaponConfig

unitConfig =
  abstract: true
  schema:
    level: 'int'
    life: 'int'
    weapon:
      type: Weapons
      localKey: 'weaponId'
      optional: true
    weaponId:
      type: 'int'
      optional: true

class Units extends Nodulator.Resource 'unit', unitConfig

  Attack: @_WrapPromise (target, done) ->
    target.life -= @weapon.hitPoints
    target.Save done

  LevelUp: @_WrapPromise (done) ->
    @level++
    @Save done

Units.Init()

class UnitRoute extends Nodulator.Route.MultiRoute
  Config: ->
    super()

    @Put '/:id/levelUp' -> it.instance.LevelUp!

    @Put '/:id/attack/:targetId' (Req) ~>
      # Hack to stay generic between children
      TargetResource = Monsters if @name is 'players'
      TargetResource = Players if @name is 'monsters'

      watcher = Nodulator.Watch ->
        Req.Send TargetResource.error! if TargetResource.error!?

      err, target <- TargetResource.Fetch +Req.params.targetId
      err <- Req.instance.Attack target
      Req.Send target
      watcher.Stop!

Players = Units.Extend 'player', UnitRoute
Monsters = Units.Extend 'monster', UnitRoute

/*
  Here stops the exemple,
  And Here start the tests.
*/

# Hack for keep track of weapon
weaponId = []

async.series do
  * addWeapon: (done) ->
      Nodulator.client.Post '/api/1/weapons', {hitPoints: 2}, (err, {body}) ->
        weaponId[*] = body.id
        done err, body

    addWeapon2: (done) ->
      Nodulator.client.Post '/api/1/weapons', {hitPoints: 1}, (err, {body}) ->
        weaponId[*] = body.id
        done err, body

    addPlayer: (done) ->
      Nodulator.client.Post '/api/1/players', {level: 1, life: 100, weaponId: weaponId.0}, (err, {body}) -> done err, body

    testGet: (done) ->
      Nodulator.client.Get '/api/1/players', (err, {body}) -> done err, body

    levelUp: (done) ->
      Nodulator.client.Put '/api/1/players/1/levelUp', {}, (err, {body}) -> done err, body

    levelUp2: (done) ->
      Nodulator.client.Put '/api/1/players/1/levelUp', {}, (err, {body}) -> done err, body

    testGetMonster: (done) ->
      Nodulator.client.Get '/api/1/monsters', (err, {body}) -> done err, body
    addMonster: (done) ->
      Nodulator.client.Post '/api/1/monsters', {level: 1, life: 20, weaponId: weaponId.1}, (err, {body}) -> done err, body

    testGetMonster2: (done) ->
      Nodulator.client.Get '/api/1/monsters', (err, {body}) -> done err, body

    levelUpMonster: (done) ->
      Nodulator.client.Put '/api/1/monsters/1/levelUp', {}, (err, {body}) -> done err, body

    levelUpMonster2: (done) ->
      Nodulator.client.Put '/api/1/monsters/1/levelUp', {}, (err, {body}) -> done err, body

    playerAttack: (done) ->
      Nodulator.client.Put '/api/1/players/1/attack/1', {}, (err, {body}) -> done err, body

    monsterAttack: (done) ->
      Nodulator.client.Put '/api/1/monsters/1/attack/1', {}, (err, {body}) -> done err, body

    monsterAttack1: (done) ->
      Nodulator.client.Put '/api/1/monsters/1/attack/1', {}, (err, {body}) -> done err, body

    monsterAttack2: (done) ->
      Nodulator.client.Put '/api/1/monsters/1/attack/1', {}, (err, {body}) -> done err, body

    monsterAttack3: (done) ->
      Nodulator.client.Put '/api/1/monsters/1/attack/1', {}, (err, {body}) -> done err, body

    monsterAttack4: (done) ->
      Nodulator.client.Put '/api/1/monsters/1/attack/1', {}, (err, {body}) -> done err, body

  , (err, results) ->
    util = require 'util'
    util.debug util.inspect err, {depth: null}
    util.debug util.inspect results, {depth: null}