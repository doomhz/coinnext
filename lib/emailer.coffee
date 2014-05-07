emailer = require("nodemailer")
fs      = require("fs")
_       = require("underscore")

class Emailer

  options: {}

  data: {}

  attachments: [
  ]

  constructor: (@options, @data)->
    @setUrls()

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

  setUrls: ()->
    @data.site_url = (GLOBAL.appConfig().emailer.host or @data.site_url)
    @data.img_path = (GLOBAL.appConfig().assets_host or @data.site_url) + "/img/email"
    @data.img_version = if GLOBAL.appConfig().assets_key then "?v=#{GLOBAL.appConfig().assets_key}" else ""

exports = module.exports = Emailer
