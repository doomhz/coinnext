window.App or= {}

class App.ErrorLogger

  constructor: ()->
    $.subscribe "error", @renderError

  renderError: (ev, xhrError = {})=>
    if xhrError.responseText
      try
        error = $.parseJSON xhrError.responseText
        error = error.error
      catch e
        error = xhrError.responseText
    else
      error = xhrError.error or xhrError
    $.jGrowl error,
      position: "top-right"
      theme: "error"