JsonBeautifier =

  constructor: ()->

  # Format JSON function
  # http://ketanjetty.com/coldfusion/javascript/format-json/
  toHTML: (jsonString)->
    jsonString = JSON.stringify(jsonString) if typeof jsonString is "object"
    jsonString.replace(/(\\'|\\")/g, "")
    retval = ''
    pos = 0
    strLen = jsonString.length
    indentStr = '&nbsp;&nbsp;&nbsp;&nbsp;'
    newLine = '<br />'
  
    for char in jsonString
      
      if char is "}" or char is "]"
        retval = retval + newLine
        pos = pos - 1
        
        j = 0
        while j < pos
          retval = retval + indentStr
          j++
      
      retval = retval + char
      
      if char is "{" or char is "[" or char is ","
        retval = retval + newLine
        pos = pos + 1  if char is "{" or char is "["
        
        k = 0
        while k < pos
          retval = retval + indentStr
          k++
  
    retval

exports = module.exports = JsonBeautifier