# -*- encoding: utf-8 -*-

from flask import json

# Will need to write documentation for this

# Main point is that category is what you see in the leksa menu, and
# things are ordered by 'level'

# NB: for testing purposes, too lazy to convert this to a python obj.
leksa_questions = [
    # -*- body -*- 

    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["BODYPART"]
                 }
    , 'answer_similarity': { 'semantics': ["BODYPART"] }
    , 'level': 1
    , 'answers': 1
    , 'points': 20
    , 'name': "Bodypart image to word"
    , 'category': "BODYPART"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["BODYPART"]
                 }
    , 'answer_similarity': { }
    , 'level': 2
    , 'answers': 2
    , 'points': 40
    , 'name': "Bodypart word to image"
    , 'category': "BODYPART"
    },
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["BODYPART"]
                 }
    , 'answer_similarity': { 'semantics': ["BODYPART"] }
    , 'level': 3
    , 'answers': 2
    , 'points': 50
    , 'name': "Bodypart image to 2-word"
    , 'category': "BODYPART"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["BODYPART"]
                 }
    , 'answer_similarity': { 'semantics': ["BODYPART"] }
    , 'level': 4
    , 'points': 60
    , 'answers': 2
    , 'name': "Bodypart word to 2-img"
    , 'category': "BODYPART"
    },
    { 'type': 'word_to_word'
    , 'filters': { 'from_language': 'sma', 'to_language': 'nob'
                 , 'semantics': ["BODYPART"]
                 }
    , 'answer_similarity': { 'features': ["BISYL", "HT"]
                           , 'semantics': ["BODYPART"]
                           }
    , 'level': 5
    , 'points': 60
    , 'answers': 4
    , 'category': "BODYPART"
    },

    # -*- heelsedh -*- 
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["GREETINGS"]
                 }
    , 'answer_similarity': { 'semantics': ["GREETINGS"] }
    , 'level': 1
    , 'answers': 1
    , 'name': "Bodypart image to word"
    , 'points': 20
    , 'category': "GREETINGS"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["GREETINGS"]
                 }
    , 'answer_similarity': { }
    , 'level': 2
    , 'answers': 2
    , 'name': "Bodypart word to image"
    , 'points': 40
    , 'category': "GREETINGS"
    },
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["GREETINGS"]
                 }
    , 'answer_similarity': { 'semantics': ["GREETINGS"] }
    , 'level': 3
    , 'answers': 2
    , 'name': "Bodypart image to 2-word"
    , 'points': 50
    , 'category': "GREETINGS"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["GREETINGS"]
                 }
    , 'answer_similarity': { 'semantics': ["GREETINGS"] }
    , 'level': 4
    , 'answers': 2
    , 'name': "Bodypart word to 2-img"
    , 'points': 60
    , 'category': "GREETINGS"
    },
    { 'type': 'word_to_word'
    , 'filters': { 'from_language': 'sma', 'to_language': 'nob'
                 , 'semantics': ["GREETINGS"]
                 }
    , 'answer_similarity': { 'features': ["BISYL", "HT"]
                           , 'semantics': ["GREETINGS"]
                           }
    , 'level': 5
    , 'points': 80
    , 'answers': 4
    , 'category': "GREETINGS"
    },

    # -*- food -*- 
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["FOOD"]
                 }
    , 'answer_similarity': { 'semantics': ["FOOD"] }
    , 'level': 1
    , 'answers': 1
    , 'name': "Bodypart image to word"
    , 'points': 20
    , 'category': "FOOD"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["FOOD"]
                 }
    , 'answer_similarity': { }
    , 'level': 2
    , 'answers': 2
    , 'name': "Bodypart word to image"
    , 'points': 40
    , 'category': "FOOD"
    },
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["FOOD"]
                 }
    , 'answer_similarity': { 'semantics': ["FOOD"] }
    , 'level': 3
    , 'answers': 2
    , 'name': "Bodypart image to 2-word"
    , 'points': 60
    , 'category': "FOOD"
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["FOOD"]
                 }
    , 'answer_similarity': { 'semantics': ["FOOD"] }
    , 'level': 4
    , 'answers': 2
    , 'name': "Bodypart word to 2-img"
    , 'points': 80
    , 'category': "FOOD"
    },
    { 'type': 'word_to_word'
    , 'filters': { 'from_language': 'sma', 'to_language': 'nob'
                 , 'semantics': ["FOOD"]
                 }
    , 'answer_similarity': { 'features': ["BISYL", "HT"]
                           , 'semantics': ["FOOD"]
                           }
    , 'level': 5
    , 'answers': 4
    , 'points': 100
    , 'category': "FOOD"
    },


]


# [ { "answer_similarity": { "features": [ "BISYL", "HT" ], "semantics": [ "BODYPART" ] }, "filters": { "from_language": "img", "semantics": [ "FAMILY" ], "to_language": "sma" }, "type": "image_to_word" }, { "answer_similarity": { "features": [ "BISYL" ], "semantics": [ "ANIMAL", "FUZZY" ] }, "filters": { "from_language": "sma", "semantics": [ "ANIMAL" ], "to_language": "img" }, "type": "word_to_image" }, { "answer_similarity": { "features": [], "semantics": [ "ANIMAL", "FUZZY" ] }, "filters": { "from_language": "sma", "semantics": [ "ANIMAL" ], "to_language": "nob" }, "type": "word_to_word" }, { "answer_similarity": { "features": [], "semantics": [ "ANIMAL", "FUZZY" ] }, "filters": { "from_language": "nob", "semantics": [ "ANIMAL" ], "to_language": "sma" }, "type": "word_to_word" } ]

sample_json = [{"language":"img","concept_type":"img","concept_value":"http://placedog.com/250/150","semantics":["ANIMAL","FAMILY","ANIMATE"],"features":["FUZZY","BROWN"],"c_id":1,"translations":[5]},{"language":"sma","concept_type":"text","concept_value":"aehtjaahka","semantics":["FAMILY","ANIMATE"],"features":["TRISYL","HK"],"c_id":2,"translations":[1,11]},{"language":"sma","concept_type":"text","concept_value":"gaahtoe","semantics":["ANIMAL","ANIMATE"],"features":["BISYL","HT","AA_ÅÅ","OE_O_E"],"c_id":3,"translations":[4,12]},{"language":"img","concept_type":"img","concept_value":"http://placekitten.com/250/150","semantics":["ANIMAL","ANIMATE"],"features":["FUZZY","CUTE","BROWN"],"c_id":4,"translations":[3]},{"language":"sma","concept_type":"text","concept_value":u"bïenje","semantics":["ANIMAL","ANIMATE"],"features":["BISYL","NJ"],"c_id":5,"translations":[1,13]},{"language":"img","concept_type":"img","concept_value":"http://dummyimage.com/250x150/000/900', u''), ('text', u'granny","semantics":["FAMILY","ANIMATE"],"features":["OLD","CUTE","WRINKLY"],"c_id":6,"translations":[2]},{"language":"img","concept_type":"img","concept_value":"http://dummyimage.com/250x150/000/900'), ('text', u'fish","semantics":["ANIMAL","ANIMATE"],"features":["SCALY","CUTE"],"c_id":7,"translations":[8]},{"language":"sma","concept_type":"text","concept_value":"guelie","semantics":["ANIMAL","ANIMATE"],"features":["UE_ÖÖ","L"],"c_id":8,"translations":[7,15]},{"language":"sma","concept_type":"text","concept_value":"riepie","semantics":["ANIMAL","ANIMATE"],"features":["BISYL","P","IE_EA"],"c_id":9,"translations":[10,14]},{"language":"img","concept_type":"img","concept_value":"http://dummyimage.com/250x150/000/900'), ('text', u'fox","semantics":["ANIMAL","ANIMATE"],"features":["FUZZY","CUTE"],"c_id":10,"translations":[9]},{"language":"nob","concept_type":"text","concept_value":"farmor","semantics":["FAMILY","ANIMATE"],"features":[],"c_id":11,"translations":[2]},{"language":"nob","concept_type":"text","concept_value":"katt","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":12,"translations":[3]},{"language":"nob","concept_type":"text","concept_value":"hund","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":13,"translations":[5]},{"language":"nob","concept_type":"text","concept_value":"rev","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":14,"translations":[9]},{"language":"nob","concept_type":"text","concept_value":"fisk","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":15,"translations":[8]},{"language":"nob","concept_type":"text","concept_value":"ekorn","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":16,"translations":[17]},{"language":"sma","concept_type":"text","concept_value":"åeruve","semantics":["ANIMAL","ANIMATE"],"features":[],"c_id":17,"translations":[16,18]},{"language":"img","concept_type":"img","concept_value":"/static/images/orava.png","semantics":["ANIMAL","ANIMATE"],"features":["FUZZY","CUTE","RED"],"c_id":18,"translations":[17]}]
