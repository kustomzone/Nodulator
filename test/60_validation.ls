_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

Tests = null

test = it

describe 'N Validation', ->

  before (done) ->
    N.Reset ->

      Tests := N 'test' schema: \strict
        ..Field \field1 \bool
        ..Field \field2 \int
        ..Field \field3 \string
        ..Field \field4 \date
        ..Field \field5 \email

      done()

  test 'should validate Resource', (done) ->
    blob =
      field1: true
      field2: 1
      field3: 'lol'
      field4: new Date()
      field5: 'test@test.fr'

    Tests.Create blob, (err, test) ->
      return done err if err?

      done()

  test 'should not validate Resource', (done) ->
    Tests.Create {}, (err, test) ->
      return done() if err?

      done new Error 'No error fields'


  test 'should not validate Resource bool', (done) ->
    blob =
      field1: 1
      field2: 1
      field3: 'lol'
      field4: new Date()
      field5: 'test@test.fr'

    Tests.Create blob, (err, test) ->
      return done() if err?

      done new Error 'No error on bool fields'

  test 'should not validate Resource int', (done) ->
    blob =
      field1: true
      field2: 'lol'
      field3: 'lol'
      field4: new Date()
      field5: 'test@test.fr'

    Tests.Create blob, (err, test) ->
      return done() if err?

      done new Error 'No error on int fields'



#  it 'should not validate Resource string', (done) ->
#    blob =
#      field1: true
#      field2: 1
#      field3: false
#      field4: new Date()
#      field5: 'test@test.fr'

#    Tests.Create blob, (err, test) ->
#      return done() if err?

#      done new Error 'No error on bool fields'
