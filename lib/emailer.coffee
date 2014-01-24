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
      #from: GLOBAL.appConfig().emailer.from
      from: "JSLogger Reporter <no-reply@jslogger.com>"
      subject: @options.subject
      html: html
      generateTextFromHTML: true
      attachments: attachments
    transport = @getTransport()
    transport.sendMail messageData, callback

  getTransport: ()->
    #emailer.createTransport "SMTP", GLOBAL.appConfig().emailer.transport
    emailer.createTransport "SMTP",
      host: "email-smtp.us-east-1.amazonaws.com"
      port: 465
      secureConnection: true
      auth:
        user: "AKIAJOFBBXEA644BT5TQ"
        pass: "AsHcx3VF6LZ0RhHxBc+EhYJnUSTwJ8HcbGUa7Tl5bzuC"

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
