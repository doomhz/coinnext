require "./../../helpers/spec_helper"
speakeasy = require "speakeasy"

describe "User", ->
  describe "hashPassword", ()->
    it "returns the hashed password", ()->
      password = "testPassword"
      GLOBAL.db.User.hashPassword(password).should.eql "f7dfe3adc9848f0d258f16ecaf79a524f13e704620a653885c913b1873774f62"
