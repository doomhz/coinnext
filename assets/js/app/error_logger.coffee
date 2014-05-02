window.App or= {}

class App.ErrorLogger

  constructor: ()->
    $.subscribe "error", @renderError
    $.subscribe "notice", @renderNotice

  renderError: (ev, xhrError = {}, $form)=>
    if xhrError.responseText
      try
        error = $.parseJSON xhrError.responseText
        error = error.error
      catch e
        error = xhrError.responseText
    else
      error = xhrError.error or xhrError
    return $form.find("#error-cnt").text error  if $form
    $.jGrowl error,
      position: "top-right"
      theme: "error"

  renderNotice: (ev, msg)=>
    $.jGrowl msg,
      position: "top-right"
      theme: "notice"