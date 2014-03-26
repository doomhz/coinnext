emailer = require("nodemailer")
fs      = require("fs")
_       = require("underscore")

class Emailer

  options: {}

  data: {}

  attachments: [
    {
      fileName: "logo.jpg"
      filePath: "./public/img/email/logo.png"
      cid: "logo@coinnext"
    }
  ]

  constructor: (@options, @data)->

  send: (callback)->
    html = @getHtml(@options.template, @data)
    attachments = @getAttachments(html)
    messageData =
      to: @options.to.email
      from: GLOBAL.appConfig().emailer.from
      subject: @options.subject
      html: html
      generateTextFromHTML: true
      attachments: attachments
    transport = @getTransport()
    return callback()  if not GLOBAL.appConfig().emailer.enabled
    transport.sendMail messageData, callback

  getTransport: ()->
    emailer.createTransport "SMTP", GLOBAL.appConfig().emailer.transport

  getHtml: (templateName, data)->
    templatePath = "./views/emails/#{templateName}.html"
    templateContent = fs.readFileSync(templatePath, encoding = "utf8")
    _.template templateContent, data, {interpolate: /\{\{(.+?)\}\}/g}

  getAttachments: (html)->
    attachments = []
    for attachment in @attachments
      attachments.push(attachment) if html.search("cid:#{attachment.cid}") > -1
    attachments

exports = module.exports = Emailer
