# -*- encoding: utf-8 -*-

from flask import json

# NB: for testing purposes, too lazy to convert this to a python obj.
leksa_questions = [
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["GROUP_1"]
                 }
    , 'answer_similarity': { 'semantics': ["GROUP_1"] }
    , 'level': 1
    , 'answers': 1
    , 'name': "Bodypart image to word"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["GROUP_1"]
                 }
    , 'answer_similarity': { }
    , 'level': 2
    , 'answers': 2
    , 'name': "Bodypart word to image"
    },
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["GROUP_1"]
                 }
    , 'answer_similarity': { 'semantics': ["GROUP_1"] }
    , 'level': 3
    , 'answers': 2
    , 'name': "Bodypart image to 2-word"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["GROUP_1"]
                 }
    , 'answer_similarity': { 'semantics': ["GROUP_1"] }
    , 'level': 4
    , 'answers': 2
    , 'name': "Bodypart word to 2-img"
    },
    { 'type': 'word_to_word'
    , 'filters': { 'from_language': 'sma', 'to_language': 'nob'
                 , 'semantics': ["GROUP_1"]
                 }
    , 'answer_similarity': { 'features': ["BISYL", "HT"]
                           , 'semantics': ["GROUP_1"]
                           }
    , 'level': 5
    , 'answers': 4
    },

    # -- group 2 -- 
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["GROUP_2"]
                 }
    , 'answer_similarity': { 'semantics': ["GROUP_2"] }
    , 'level': 5
    , 'answers': 1
    , 'name': "Bodypart image to word"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["GROUP_2"]
                 }
    , 'answer_similarity': { }
    , 'level': 6
    , 'answers': 2
    , 'name': "Bodypart word to image"
    },
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["GROUP_2"]
                 }
    , 'answer_similarity': { 'semantics': ["GROUP_2"] }
    , 'level': 7
    , 'answers': 2
    , 'name': "Bodypart image to 2-word"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["GROUP_2"]
                 }
    , 'answer_similarity': { 'semantics': ["GROUP_2"] }
    , 'level': 8
    , 'answers': 2
    , 'name': "Bodypart word to 2-img"
    },
    { 'type': 'word_to_word'
    , 'filters': { 'from_language': 'sma', 'to_language': 'nob'
                 , 'semantics': ["GROUP_2"]
                 }
    , 'answer_similarity': { 'features': ["BISYL", "HT"]
                           , 'semantics': ["GROUP_2"]
                           }
    , 'level': 9
    , 'answers': 4
    },

    # -- group 3 -- 
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["GROUP_3"]
                 }
    , 'answer_similarity': { 'semantics': ["GROUP_3"] }
    , 'level': 10
    , 'answers': 1
    , 'name': "Bodypart image to word"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["GROUP_3"]
                 }
    , 'answer_similarity': { }
    , 'level': 11
    , 'answers': 2
    , 'name': "Bodypart word to image"
    },
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["GROUP_3"]
                 }
    , 'answer_similarity': { 'semantics': ["GROUP_3"] }
    , 'level': 12
    , 'answers': 2
    , 'name': "Bodypart image to 2-word"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["GROUP_3"]
                 }
    , 'answer_similarity': { 'semantics': ["GROUP_3"] }
    , 'level': 13
    , 'answers': 2
    , 'name': "Bodypart word to 2-img"
    },
    { 'type': 'word_to_word'
    , 'filters': { 'from_language': 'sma', 'to_language': 'nob'
                 , 'semantics': ["GROUP_3"]
                 }
    , 'answer_similarity': { 'features': ["BISYL", "HT"]
                           , 'semantics': ["GROUP_3"]
                           }
    , 'level': 14
    , 'answers': 4
    },

    # { 'type': 'word_to_image'
    # , 'filters': { 'from_language': 'sma', 'to_language': 'img'
    #              , 'semantics': ["BODYPART"]
    #              }
    # , 'answer_similarity': { 'features': ["FACE"]
    #                        }
    # }
  # , { 'type': 'word_to_word'
  #   , 'filters': { 'from_language': 'sma', 'to_language': 'nob'
  #                , 'semantics': ["ANIMAL_PET"]
  #                }
    # , 'answer_similarity': { 'features': ["BISYL", "HT"]
    #                        , 'semantics': ["ANIMAL_PET"]
    #                        }
  #   }
  # , { 'type': 'word_to_word'
  #   , 'filters': { 'from_language': 'sma', 'to_language': 'nob'
  #                , 'semantics': ["MORFAS"]
  #                }
  #   }
  # , { 'type': 'word_to_word'
  #   , 'filters': { 'from_language': 'nob', 'to_language': 'sma'
  #                , 'semantics': ["MORFAS"]
  #                }
  #   }
]


# [ { "answer_similarity": { "features": [ "BISYL", "HT" ], "semantics": [ "BODYPART" ] }, "filters": { "from_language": "img", "semantics": [ "FAMILY" ], "to_language": "sma" }, "type": "image_to_word" }, { "answer_similarity": { "features": [ "BISYL" ], "semantics": [ "ANIMAL", "FUZZY" ] }, "filters": { "from_language": "sma", "semantics": [ "ANIMAL" ], "to_language": "img" }, "type": "word_to_image" }, { "answer_similarity": { "features": [], "semantics": [ "ANIMAL", "FUZZY" ] }, "filters": { "from_language": "sma", "semantics": [ "ANIMAL" ], "to_language": "nob" }, "type": "word_to_word" }, { "answer_similarity": { "features": [], "semantics": [ "ANIMAL", "FUZZY" ] }, "filters": { "from_language": "nob", "semantics": [ "ANIMAL" ], "to_language": "sma" }, "type": "word_to_word" } ]

sample_json = [{"language":"img","concept_type":"img","concept_value":"http://placedog.com/250/150","semantics":["ANIMAL","FAMILY","ANIMATE"],"features":["FUZZY","BROWN"],"c_id":1,"translations":[5]},{"language":"sma","concept_type":"text","concept_value":"aehtjaahka","semantics":["FAMILY","ANIMATE"],"features":["TRISYL","HK"],"c_id":2,"translations":[1,11]},{"language":"sma","concept_type":"text","concept_value":"gaahtoe","semantics":["ANIMAL","ANIMATE"],"features":["BISYL","HT","AA_ÅÅ","OE_O_E"],"c_id":3,"translations":[4,12]},{"language":"img","concept_type":"img","concept_value":"http://placekitten.com/250/150","semantics":["ANIMAL","ANIMATE"],"features":["FUZZY","CUTE","BROWN"],"c_id":4,"translations":[3]},{"language":"sma","concept_type":"text","concept_value":u"bïenje","semantics":["ANIMAL","ANIMATE"],"features":["BISYL","NJ"],"c_id":5,"translations":[1,13]},{"language":"img","concept_type":"img","concept_value":"http://dummyimage.com/250x150/000/900', u''), ('text', u'granny","semantics":["FAMILY","ANIMATE"],"features":["OLD","CUTE","WRINKLY"],"c_id":6,"translations":[2]},{"language":"img","concept_type":"img","concept_value":"http://dummyimage.com/250x150/000/900'), ('text', u'fish","semantics":["ANIMAL","ANIMATE"],"features":["SCALY","CUTE"],"c_id":7,"translations":[8]},{"language":"sma","concept_type":"text","concept_value":"guelie","semantics":["ANIMAL","ANIMATE"],"features":["UE_ÖÖ","L"],"c_id":8,"translations":[7,15]},{"language":"sma","concept_type":"text","concept_value":"riepie","semantics":["ANIMAL","ANIMATE"],"features":["BISYL","P","IE_EA"],"c_id":9,"translations":[10,14]},{"language":"img","concept_type":"img","concept_value":"http://dummyimage.com/250x150/000/900'), ('text', u'fox","semantics":["ANIMAL","ANIMATE"],"features":["FUZZY","CUTE"],"c_id":10,"translations":[9]},{"language":"nob","concept_type":"text","concept_value":"farmor","semantics":["FAMILY","ANIMATE"],"features":[],"c_id":11,"translations":[2]},{"language":"nob","concept_type":"text","concept_value":"katt","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":12,"translations":[3]},{"language":"nob","concept_type":"text","concept_value":"hund","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":13,"translations":[5]},{"language":"nob","concept_type":"text","concept_value":"rev","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":14,"translations":[9]},{"language":"nob","concept_type":"text","concept_value":"fisk","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":15,"translations":[8]},{"language":"nob","concept_type":"text","concept_value":"ekorn","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":16,"translations":[17]},{"language":"sma","concept_type":"text","concept_value":"åeruve","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":17,"translations":[16,18]},{"language":"img","concept_type":"img","concept_value":"/static/images/orava.png","semantics":["ANIMAL","ANIMATE"],"features":["FUZZY","CUTE","RED"],"c_id":18,"translations":[17]}]
