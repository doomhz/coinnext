class App.MasterView extends Backbone.View

  template: (data)->
    tpl = $.tmpload
      id: @tpl
    tpl data