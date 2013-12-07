require "./../../helpers/spec_helper"

describe "User", ->
  describe "hashPassword", ()->
    it "returns the hashed password", ()->
      password = "testPassword"
      User.hashPassword(password).should.eql "7956e77278fcf84375e188c91ad5e4d9a83d44a3"

  describe "save", ()->
    it "hashes the password before the save", (done)->
      user = new User
        email : "testEmail"
        password : "testPassword"
      user.save ()->
        user.password.should.eql "7956e77278fcf84375e188c91ad5e4d9a83d44a3"
        done()
