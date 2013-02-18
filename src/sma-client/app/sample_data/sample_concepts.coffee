Concept = require 'models/concept'

IMG_WIDTH = "250"
IMG_HEIGHT = "150"

module.exports = [ new Concept({ language: "img"
                                 , concept_type: "img"
                                 , concept_value: "http://placedog.com/#{IMG_WIDTH}/#{IMG_HEIGHT}"
                                 , semantics: [ "ANIMAL", "FAMILY", "ANIMATE" ]
                                 , features: [ "FUZZY", "BROWN" ]
                                 , c_id: 1
                                 , translations: [5]
                                 })
                   , new Concept({ language: "sma"
                                 , concept_type: "text"
                                 , concept_value: "aehtjaahka"
                                 , semantics: [ "FAMILY", "ANIMATE" ]
                                 , features: [ "TRISYL" , "HK" ]
                                 , c_id: 2
                                 , translations: [1, 11]
                                 })
                   , new Concept({ language: "sma"
                                 , concept_type: "text"
                                 , concept_value: "gaahtoe"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ "BISYL" , "HT" , "AA_ÅÅ" , "OE_O_E" ]
                                 , c_id: 3
                                 , translations: [4, 12]
                                 })
                   , new Concept({ language: "img"
                                 , concept_type: "img"
                                 , concept_value: "http://placekitten.com/#{IMG_WIDTH}/#{IMG_HEIGHT}"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ "FUZZY", "CUTE", "BROWN" ]
                                 , c_id: 4
                                 , translations: [3]
                                 })
                   , new Concept({ language: "sma"
                                 , concept_type: "text"
                                 , concept_value: "bïenje"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ "BISYL" , "NJ" ]
                                 , c_id: 5
                                 , translations: [1, 13]
                                 })
                   , new Concept({ language: "img"
                                 , concept_type: "img"
                                 , concept_value: "http://dummyimage.com/#{IMG_WIDTH}x#{IMG_HEIGHT}/000/900&text=granny"
                                 , semantics: [ "FAMILY", "ANIMATE" ]
                                 , features: [ "OLD", "CUTE", "WRINKLY" ]
                                 , c_id: 6
                                 , translations: [2]
                                 })
                   , new Concept({ language: "img"
                                 , concept_type: "img"
                                 , concept_value: "http://dummyimage.com/#{IMG_WIDTH}x#{IMG_HEIGHT}/000/900&text=fish"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ "SCALY", "CUTE"]
                                 , c_id: 7
                                 , translations: [8]
                                 })
                   , new Concept({ language: "sma"
                                 , concept_type: "text"
                                 , concept_value: "guelie"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ "UE_ÖÖ", "L" ]
                                 , c_id: 8
                                 , translations: [7, 15]
                                 })
                   , new Concept({ language: "sma"
                                 , concept_type: "text"
                                 , concept_value: "riepie"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ "BISYL" , "P", "IE_EA"]
                                 , c_id: 9
                                 , translations: [10, 14]
                                 })
                   , new Concept({ language: "img"
                                 , concept_type: "img"
                                 , concept_value: "http://dummyimage.com/#{IMG_WIDTH}x#{IMG_HEIGHT}/000/900&text=fox"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ "FUZZY", "CUTE"]
                                 , c_id: 10
                                 , translations: [9]
                                 })
                   
                   ##
                   ## Some norwegian test words
                   ##
                   , new Concept({ language: "nob"
                                 , concept_type: "text"
                                 , concept_value: "farmor"
                                 , semantics: [ "FAMILY", "ANIMATE" ]
                                 , features: [ ]
                                 , c_id: 11
                                 , translations: [2]
                                 })
                   , new Concept({ language: "nob"
                                 , concept_type: "text"
                                 , concept_value: "katt"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ ]
                                 , c_id: 12
                                 , translations: [3]
                                 })
                   , new Concept({ language: "nob"
                                 , concept_type: "text"
                                 , concept_value: "hund"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ ]
                                 , c_id: 13
                                 , translations: [5]
                                 })
                   , new Concept({ language: "nob"
                                 , concept_type: "text"
                                 , concept_value: "rev"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ ]
                                 , c_id: 14
                                 , translations: [9]
                                 })
                   , new Concept({ language: "nob"
                                 , concept_type: "text"
                                 , concept_value: "fisk"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ ]
                                 , c_id: 15
                                 , translations: [8]
                                 })
                   , new Concept({ language: "nob"
                                 , concept_type: "text"
                                 , concept_value: "ekorn"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ ]
                                 , c_id: 16
                                 , translations: [17]
                                 })
                   , new Concept({ language: "sma"
                                 , concept_type: "text"
                                 , concept_value: "åeruve"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ ]
                                 , c_id: 17
                                 , translations: [16, 18]
                                 })
                   , new Concept({ language: "img"
                                 , concept_type: "img"
                                 , concept_value: "/images/orava.png"
                                 , semantics: [ "ANIMAL", "ANIMATE" ]
                                 , features: [ "FUZZY", "CUTE", "RED" ]
                                 , c_id: 18
                                 , translations: [17]
                                 })
]

