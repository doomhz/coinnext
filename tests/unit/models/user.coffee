require "./../../helpers/spec_helper"
speakeasy = require "speakeasy"

describe "User", ->
  describe "hashPassword", ()->
    it "returns the hashed password", ()->
      password = "testPassword"
      GLOBAL.db.User.hashPassword(password).should.eql "7956e77278fcf84375e188c91ad5e4d9a83d44a3"
