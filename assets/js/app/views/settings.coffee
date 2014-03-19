class App.SettingsView extends App.MasterView

  tpl: null

  model: null

  googleAuthModel: null

  events:
    "click #qr-gen-bt": "onQrGenClick"
    "submit #gauth-confirm-disable-form": "onGauthDisableConfirmSubmit"
    "submit #gauth-confirm-enable-form": "onGauthEnableConfirmSubmit"
    "change input[type='checkbox']": "onSettingsChange"

  initialize: (options = {})->

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