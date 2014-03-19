$(document).ready ()->

  $signupForm = $("#signup-form")
  $loginForm = $("#login-form")
  $changePassForm = $("#change-pass-form")
  $setNewPassForm = $("#set-new-pass-form")
  $sendPassForm = $("#send-pass-form")
  $logoutBt = $("#logout-bt")
  $pwField = $signupForm.find("[name='password']")


  onAuthSubmit = (ev)->
    ev.preventDefault()
    $form = $(ev.target)
    submitAuthForm $form

  submitAuthForm = ($form)->
    $form.find("#error-cnt").text ""
    url = $form.attr "action"
    user = new App.UserModel
      email: $form.find("[name='email']").val()
      password: $form.find("[name='password']").val()
      gauth_pass: $form.find("[name='gauth_pass']").val()
    user.url = "#{url}"
    user.save null,
      success: ()->
        if url isnt "/login"
          user.url = "/login"
          user.save null,
            success: ()->
              window.location = "/"
        else
          window.location = "/"
      error: (model, response)->
        if response.responseJSON and response.responseJSON.error
            $form.find("#error-cnt").text response.responseJSON.error
          else
            $form.find("#error-cnt").text "Invalid credentials."

  # Password Strength Meter
  switchOffAllCells = ->
    switchOffCell 0
    switchOffCell 1
    switchOffCell 2
    switchOffCell 3
    switchOffCell 4

  indicateStrength = (str) ->
    text = document.getElementById("strength-text")
    text.innerHTML = str  if text
  
  switchOffCell = (number) ->
    cell = document.getElementById("s" + number)
    cell.className = "cell"

  switchOnCell = (number) ->
    cell = document.getElementById("s" + number)
    cell.className = "cell on"

  $pwField.keyup ()->
    result = zxcvbn($pwField.val())
    score = result.score
    switchOffAllCells()
    switch score
      when 0
        switchOnCell 0
        indicateStrength "Very weak"
      when 1
        switchOnCell 0
        switchOnCell 1
        indicateStrength "Weak"
      when 2
        switchOnCell 0
        switchOnCell 1
        switchOnCell 2
        indicateStrength "Adequate"
      when 3
        switchOnCell 0
        switchOnCell 1
        switchOnCell 2
        switchOnCell 3
        indicateStrength "Pretty good"
      when 4
        switchOnCell 0
        switchOnCell 1
        switchOnCell 2
        switchOnCell 3
        switchOnCell 4
        indicateStrength "Excellent"
      else
        swichOnCell 0

  if $signupForm.length
    $signupForm.validate
      rules:
        password:
          required: true
          minlength: 5
        repeat_password:
          required: true
          minlength: 5
          equalTo: "#signup-password"
        email:
          required: true
          email: true
      messages:
        password:
          required: "Please provide a password."
          minlength: "Your password must be at least 5 characters long."
        repeat_password:
          required: "Please provide a password."
          minlength: "Your password must be at least 5 characters long."
          equalTo: "Please enter the same password as above."
        email: "Please enter a valid email address."
      submitHandler: ()->
        submitAuthForm $signupForm
        return false

  if $changePassForm
    $changePassForm.validate
      rules:
        password:
          required: true
          minlength: 5
        repeat_password:
          required: true
          minlength: 5
          equalTo: "#change-pass-new-pass"
      messages:
        password:
          required: "Please provide a password."
          minlength: "Your password must be at least 5 characters long."
        repeat_password:
          required: "Please provide a password."
          minlength: "Your password must be at least 5 characters long."
          equalTo: "Please enter the same password as above."

  if $setNewPassForm
    $setNewPassForm.validate
      rules:
        password:
          required: true
        new_password:
          required: true
          minlength: 5
        repeat_new_password:
          required: true
          minlength: 5
          equalTo: "#set-new-pass"
      messages:
        password:
          required: "Please provide current password."
        new_password:
          required: "Please provide a new password."
          minlength: "Your password must be at least 5 characters long."
        repeat_new_password:
          required: "Please provide a password."
          minlength: "Your password must be at least 5 characters long."
          equalTo: "Please enter the same password as above."
      submitHandler: ()->
        $form = $setNewPassForm
        $form.find("#error-cnt").text ""
        url = $form.attr "action"
        user = new App.UserModel
          password: $form.find("[name='password']").val()
          new_password: $form.find("[name='new_password']").val()
        user.url = "#{url}"
        user.save null,
          success: ()->
            $form.find("#notice-cnt").text "The password was successfully changed."
          error: (model, response)->
            if response.responseJSON and response.responseJSON.error
              $form.find("#error-cnt").text response.responseJSON.error
        return false

  if $sendPassForm
    $sendPassForm.validate
      rules:
        email:
          required: true
          email: true
      messages:
        email: "Please enter a valid email address."

  if $loginForm.length
    $loginForm.submit onAuthSubmit

  if $logoutBt.length
    $logoutBt.click (ev)->
      ev.preventDefault()
      $.get $logoutBt.attr("href"), ()->
        window.location = "/"
