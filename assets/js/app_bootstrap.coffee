$(document).ready ()->

  $signupForm = $("#signup-form")
  $loginForm = $("#login-form")
  $changePassForm = $("#change-pass-form")
  $sendPassForm = $("#send-pass-form")
  $logoutBt = $("#logout-bt")
  $qrGenBt = $("#qr-gen-bt")

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

  if $qrGenBt.length
    $qrGenBt.click (ev)->
      ev.preventDefault()
      if confirm "Are you sure?"
        $.get $qrGenBt.attr("href"), ()->
          window.location.reload()
