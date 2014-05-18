window.App = window.App or {}
window.App.Helpers = window.App.Helpers or {}
window.App.Helpers.CryptoCurrency =

  isValidAddress: (address) ->
    decoded = @base58_decode(address)
    return false  unless decoded.length is 25
    true
    #cksum = decoded.substr(decoded.length - 4)
    #rest = decoded.substr(0, decoded.length - 4)
    #good_cksum = @hex2a(sha256_digest(@hex2a(sha256_digest(rest)))).substr(0, 4)
    #return false  unless cksum is good_cksum
    #true
  
  base58_decode: (string) ->
    table = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    table_rev = new Array()
    i = undefined
    i = 0
    while i < 58
      table_rev[table[i]] = int2bigInt(i, 8, 0)
      i++
    l = string.length
    long_value = int2bigInt(0, 1, 0)
    num_58 = int2bigInt(58, 8, 0)
    c = undefined
    i = 0
    while i < l
      c = string[l - i - 1]
      long_value = add(long_value, mult(table_rev[c], @pow(num_58, i)))
      i++
    hex = bigInt2str(long_value, 16)
    str = @hex2a(hex)
    nPad = undefined
    nPad = 0
    while string[nPad] is table[0]
      nPad++
    output = str
    output = @repeat("\u0000", nPad) + str  if nPad > 0
    output
  
  hex2a: (hex) ->
    str = ""
    i = 0

    while i < hex.length
      str += String.fromCharCode(parseInt(hex.substr(i, 2), 16))
      i += 2
    str
  
  pow: (big, exp) ->
    return int2bigInt(1, 1, 0)  if exp is 0
    i = undefined
    newbig = big
    i = 1
    while i < exp
      newbig = mult(newbig, big)
      i++
    newbig
  
  repeat: (s, n) ->
    a = []
    a.push s  while a.length < n
    a.join ""