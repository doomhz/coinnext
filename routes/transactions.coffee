Transaction = GLOBAL.db.Transaction
JsonRenderer = require "../lib/json_renderer"

module.exports = (app)->

  app.get "/transactions/pending/:wallet_id", (req, res)->
    walletId = req.params.wallet_id
    return JsonRenderer.error "Please auth.", res  if not req.user
    Transaction.findPendingByUserAndWallet req.user.id, walletId, (err, transactions)->
      console.error err  if err
      return JsonRenderer.error "Sorry, could not get pending transactions...", res  if err
      res.json JsonRenderer.transactions transactions

  app.get "/transactions/processed/:wallet_id", (req, res)->
    walletId = req.params.wallet_id
    return JsonRenderer.error "Please auth.", res  if not req.user
    Transaction.findProcessedByUserAndWallet req.user.id, walletId, (err, transactions)->
      console.error err  if err
      return JsonRenderer.error "Sorry, could not get processed transactions...", res  if err
      res.json JsonRenderer.transactions transactions

  app.get "/transactions/:id", (req, res)->
    id = req.params.id
    return JsonRenderer.error "Please auth.", res  if not req.user
    Transaction.find(id).complete (err, transaction)->
      console.error err  if err
      return JsonRenderer.error "Sorry, could not find transaction...", res  if err
      res.json JsonRenderer.transaction transaction
