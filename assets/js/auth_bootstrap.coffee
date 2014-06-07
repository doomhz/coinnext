$(document).ready ()->

  $signupForm = $("#signup-form")
  $loginForm = $("#login-form")
  $changePassForm = $("#change-pass-form")
  $setNewPassForm = $("#set-new-pass-form")
  $sendPassForm = $("#send-pass-form")
  $logoutBt = $("#logout-bt")
  $pwField = $signupForm.find("[name='password']")
  $hint = $("#hint")
  $email = $("#signup-email")

  $.validator.addMethod "onenumber", (value, element)->
      pattern = /[0-9]{1,}/
      return @optional(element) or pattern.test(value)
    , "The password should contain at least one number."

  $email.on "blur", ->
    $(this).mailcheck
      suggested: (element, suggestion) ->
        unless $hint.html()
          suggestion = "Did you mean <span class='suggestion'>" + "<span class='address'>" + suggestion.address + "</span>" + "@<a href='#' class='domain'>" + suggestion.domain + "</a></span>?"
          $hint.html(suggestion).show()
        else
          $(".address").html(suggestion.address);
          $(".domain").html(suggestion.domain);
      empty: (element) ->
        $hint.empty().hide()

  $hint.on "click", ".domain", ->
    $email.val $(".suggestion").text()
    $hint.empty().hide()

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
  setStrength = (number) ->
    $("#password-strength").removeClass().addClass(""+number+"")
    
  setText = (text) ->
    $("#strength-text").html text

  $pwField.keyup ()->
    result = zxcvbn($pwField.val())
    score = result.score
    switch score
      when 0
        setStrength "veryweak"
        setText "Very weak password"
      when 1
        setStrength "weak"
        setText "Weak password"
      when 2
        setStrength "adequate"
        setText "Adequate password"
      when 3
        setStrength "prettygood"
        setText "Pretty good password"
      when 4
        setStrength "excellent"
        setText "Excellent password"

  if $signupForm.length
    $signupForm.validate
      rules:
        password:
          required: true
          minlength: 8
          onenumber: true
        repeat_password:
          required: true
          minlength: 8
          equalTo: "#signup-password"
        email:
          required: true
          email: true
      messages:
        password:
          required: "Please provide a password."
          minlength: "Your password must be at least 8 characters long."
        repeat_password:
          required: "Please provide a password."
          minlength: "Your password must be at least 8 characters long."
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
          minlength: 8
          onenumber: true
        repeat_password:
          required: true
          minlength: 8
          equalTo: "#change-pass-new-pass"
      messages:
        password:
          required: "Please provide a password."
          minlength: "Your password must be at least 8 characters long."
        repeat_password:
          required: "Please provide a password."
          minlength: "Your password must be at least 8 characters long."
          equalTo: "Please enter the same password as above."

  if $setNewPassForm
    $setNewPassForm.validate
      rules:
        password:
          required: true
        new_password:
          required: true
          minlength: 8
          onenumber: true
        repeat_new_password:
          required: true
          minlength: 8
          equalTo: "#set-new-pass"
      messages:
        password:
          required: "Please provide current password."
        new_password:
          required: "Please provide a new password."
          minlength: "Your password must be at least 8 characters long."
        repeat_new_password:
          required: "Please provide a password."
          minlength: "Your password must be at least 8 characters long."
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
