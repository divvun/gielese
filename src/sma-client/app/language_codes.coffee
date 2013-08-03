
#    ISOConv has some features for easily converting between language codes.

do (global = window, _, Backbone) ->
  class ISOConv
    VERSION: '0.0.1'

    constructor: () ->
      console.log "ISOConv"

      for k, v of @ISOs
        if not @reverseISOs[v]?
          @reverseISOs[v] = k


    reverseISOs:
      "nob": "no"

    ISOs:
      "no": "nob"
      "nb": "nob"
      "nn": "nno"
      "sv": "swe"
      "fi": "fin"
      "en": "eng"

    # set some initial special things, otherwise the rest are automatically
    # compiled from @ISOs

    two_to_three: (two) ->
      if @ISOs[two]?
        return @ISOs[two]
      else
        return two

    three_to_two: (three) ->
      if @reverseISOs[three]?
        return @reverseISOs[three]
      else
        return three

  global.ISOs = new ISOConv()

