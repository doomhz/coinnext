class App.SettingsView extends App.MasterView

  tpl: null

  model: null

  googleAuthModel: null

  events:
    "click #qr-gen-bt": "onQrGenClick"
    "submit #gauth-confirm-disable-form": "onGauthDisableConfirmSubmit"
    "submit #gauth-confirm-enable-form": "onGauthEnableConfirmSubmit"
    "change input[type='checkbox']": "onSettingsChange"
    "blur #username": "onUsernameBlur"

  initialize: (options = {})->
    $.validator.addMethod "username", (value, element)->
        pattern = /^[a-zA-Z0-9_]{4,15}$/
        return @optional(element) or pattern.test(value)
      , "The username can have only letters, numbers and underscores."
    @$("#username-update-form").validate
      rules:
        username:
          required: true
          minlength: 4
          maxlength: 15
          username: true
      submitHandler: (form, ev)=>
        @onUsernameFormSubmit ev
        return false

  onQrGenClick: (ev)->
    ev.preventDefault()
    @googleAuthModel = new App.GoogleAuthModel
    @googleAuthModel.save null,
      success: ()=>
        @$("#gauth-link").attr "href", @googleAuthModel.get "gauth_qr"
        @$("#gauth-qr").attr "src", @googleAuthModel.get "gauth_qr"
        @$("#gauth-key").text @googleAuthModel.get "gauth_key"
        @$("#gauth-cnt").removeClass "hidden"
        $(ev.target).remove()
      error: (m, xhr)->
        $.publish "error", xhr

  onGauthEnableConfirmSubmit: (ev)->
    ev.preventDefault()
    $form = $(ev.target)
    data =
      id: Date.now()
      gauth_pass: $form.find("[name='gauth_pass']").val()
    @googleAuthModel.set data
    @googleAuthModel.save null,
      success: ()->
        window.location.reload()
      error: (m, xhr)->
        $.publish "error", xhr

  onGauthDisableConfirmSubmit: (ev)->
    ev.preventDefault()
    $form = $(ev.target)
    data =
      id: Date.now()
      gauth_pass: $form.find("[name='gauth_pass']").val()
    @googleAuthModel = new App.GoogleAuthModel data
    @googleAuthModel.destroy
      data: $.param data
      success: ()->
        window.location.reload()
      error: (m, xhr)->
        $.publish "error", xhr

  onSettingsChange: (ev)->
    $input = $(ev.target)
    data = {}
    data[$input.attr("name")] = $input.is(":checked")
    @model.save data,
      success: ()->
        $.publish "error", "Settings successfully saved."
      error: (m, xhr)->
        $.publish "error", xhr

  onUsernameBlur: (ev)->
    @$("#username-update-form").submit()

  onUsernameFormSubmit: (ev)->
    ev.preventDefault()
    $form = $(ev.target)
    data =
      username: $form.find("[name='username']").val()
    return  if data.username is @model.get("username")
    @model.save data,
      success: ()->
        $.publish "error", "Username was successfully saved."
      error: (m, xhr)->
        $.publish "error", xhr
