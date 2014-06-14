#
# Requirements
#

Modulator = require './lib/Modulator'

# NOT WORKING NOW
Modulator.Config
  dbType: 'SqlMem'
  dbAuth:
    host: 'localhost'
    user: 'test'
    pass: 'test'
    database: 'test'

#
# Resources declaration
#

APlayer = Modulator.Resource 'player'

# Weapon resource will not be extended, so we named it that way to keep things clear
WeaponResource = Modulator.Resource 'weapon'

AMonster = Modulator.Resource 'monster'

#
# Resources extension
#

class PlayerResource extends APlayer

  # We override the constructor to attach a weapon
  constructor: (blob, @weapon) ->
    # Never forget to call the super with blob attached
    # If you do, you'll have to define yourself properties attached to blob
    super blob

  # New instance method
  # Fields are dynamics. They depend on what you saved
  LevelUp: (done) ->
    @level++
    @Save done

  # New instance method to attack a target
  # Here we take the weapon attached to get hitPoints
  Attack: (target, done) ->
    target.life -= @weapon.hitPoint
    target.Save done

  # Overriding of APlayer's @Deserialize class method to fetch and attach Weapon
  @Deserialize: (blob, done) ->
    WeaponResource.Fetch blob.weapon_id, (err, weapon) ->
      return done err if err?

      done null, new PlayerResource blob, weapon

class MonsterResource extends AMonster

  # Here we only define a new Attack instance method
  Attack: (target, done) ->
    target.life -= @hitPoint
    target.Save done

#
# Routes extension
#

# Player LevelUp
PlayerResource.Route 'put', '/:id/levelUp', (req, res) ->
  PlayerResource.Fetch req.params.id, (err, player) ->
    return res.send 500 if err?

    player.LevelUp (err) ->
      return res.send 500 if err?

      res.send 200, player.ToJSON()

# Player Attack
PlayerResource.Route 'put', '/:id/attack/:monsterId', (req, res) ->
  PlayerResource.Fetch req.params.id, (err, player) ->
    return res.send 500 if err?

    MonsterResource.Fetch req.params.monsterId, (err, monster) ->
      return res.send 500 if err?

      player.Attack monster, (err) ->
        return res.send 500 if err?

        res.send 200, monster.ToJSON()

# Monster Attack
MonsterResource.Route 'put', '/:id/attack/:playerId', (req, res) ->
  MonsterResource.Fetch req.params.id, (err, monster) ->
    return res.send 500 if err?

    PlayerResource.Fetch req.params.playerId, (err, player) ->
      return res.send 500 if err?

      monster.Attack player, (err) ->
        return res.send 500 if err?

        res.send 200, player.ToJSON()

#
# Default values
#

toAdd =
  hitPoint: 2

WeaponResource.Deserialize toAdd, (err, weapon) ->
  return res.send 500 if err?

  weapon.Save (err) ->
    return res.send 500 if err?

    # Now that we have a weapon, we attach it as we create the player
    toAdd =
      life: 10
      level: 1
      weapon_id: weapon.id

    PlayerResource.Deserialize toAdd, (err, player) ->
      return res.send 500 if err?

      player.Save (err) ->
        return res.send 500 if err?

toAdd =
  life: 10
  hitPoint: 1

MonsterResource.Deserialize toAdd, (err, monster) ->
  return res.send 500 if err?

  monster.Save (err) ->
    return res.send 500 if err?
