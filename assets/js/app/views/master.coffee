class App.MasterView extends Backbone.View

  template: (data)->
    tpl = $.tmpload
      id: @tpl
    tpl data

  toggleVisible: ()=>
    if @$el.is ":empty"
      @$el.parents(".container:first").hide()
    else
      @$el.parents(".container:first").show()