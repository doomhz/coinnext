$(document).ready ()->

  $signupForm = $("#signup-form")
  $loginForm = $("#login-form")
  $logoutBt = $("#logout-bt")
  $qrGenBt = $("#qr-gen-bt")

  onAuthSubmit = (ev)->
    ev.preventDefault()
    $form = $(ev.target)
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
    $signupForm.submit onAuthSubmit

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
      if confirm "Are yousure?"
        $.get $qrGenBt.attr("href"), ()->
          window.location.reload()
