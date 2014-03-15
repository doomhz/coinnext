(function() {
  var JsonBeautifier, exports;

  JsonBeautifier = {
    constructor: function() {},
    toHTML: function(jsonString) {
      var char, indentStr, j, k, newLine, pos, retval, strLen, _i, _len;
      if (typeof jsonString === "object") {
        jsonString = JSON.stringify(jsonString);
      }
      jsonString.replace(/(\\'|\\")/g, "");
      retval = '';
      pos = 0;
      strLen = jsonString.length;
      indentStr = '&nbsp;&nbsp;&nbsp;&nbsp;';
      newLine = '<br />';
      for (_i = 0, _len = jsonString.length; _i < _len; _i++) {
        char = jsonString[_i];
        if (char === "}" || char === "]") {
          retval = retval + newLine;
          pos = pos - 1;
          j = 0;
          while (j < pos) {
            retval = retval + indentStr;
            j++;
          }
        }
        retval = retval + char;
        if (char === "{" || char === "[" || char === ",") {
          retval = retval + newLine;
          if (char === "{" || char === "[") {
            pos = pos + 1;
          }
          k = 0;
          while (k < pos) {
            retval = retval + indentStr;
            k++;
          }
        }
      }
      return retval;
    }
  };

  exports = module.exports = JsonBeautifier;

}).call(this);
