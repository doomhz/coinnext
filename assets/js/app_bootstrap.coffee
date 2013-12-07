$(document).ready ()->

  $signupForm = $("#signup-form")

  if $signupForm.length
    $signupForm.submit (ev)->
      ev.preventDefault()
      $signupForm.find("#error-cnt").text ""
      user = new App.UserModel
        email: $signupForm.find("[name='email']").val()
        password: $signupForm.find("[name='password']").val()
      user.save null,
        success: ()->
          window.location = "/"
        error: (model, response)->
          if response.responseJSON.error
            $signupForm.find("#error-cnt").text response.responseJSON.error