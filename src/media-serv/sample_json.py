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
    , 'sound': False
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
    , 'sound': True
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
    , 'sound': False
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
    , 'sound': True
    },
    { 'type': 'word_to_word'
    , 'filters': { 'from_language': 'sma', 'to_language': 'USERLANG'
                 , 'semantics': ["BODYPART"]
                 }
    , 'answer_similarity': { 'features': ["BISYL", "HT"]
                           , 'semantics': ["BODYPART"]
                           }
    , 'level': 5
    , 'points': 60
    , 'answers': 4
    , 'category': "BODYPART"
    , 'sound': True
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
    , 'sound': False
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
    , 'sound': True
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
    , 'sound': False
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
    , 'sound': True
    },
    { 'type': 'word_to_word'
    , 'filters': { 'from_language': 'sma', 'to_language': 'USERLANG'
                 , 'semantics': ["GREETINGS"]
                 }
    , 'answer_similarity': { 'features': ["BISYL", "HT"]
                           , 'semantics': ["GREETINGS"]
                           }
    , 'level': 5
    , 'points': 80
    , 'answers': 4
    , 'category': "GREETINGS"
    , 'sound': False
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
    , 'sound': False
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
    , 'sound': True
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
    , 'sound': False
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
    , 'sound': True
    },
    { 'type': 'word_to_word'
    , 'filters': { 'from_language': 'sma', 'to_language': 'USERLANG'
                 , 'semantics': ["FOOD"]
                 }
    , 'answer_similarity': { 'features': ["BISYL", "HT"]
                           , 'semantics': ["FOOD"]
                           }
    , 'level': 5
    , 'answers': 4
    , 'points': 100
    , 'category': "FOOD"
    , 'sound': True
    },

    # -*- test -*- 
    { 'type': 'image_to_word'
    , 'filters': { 'from_language': 'img', 'to_language': 'sma'
                 , 'semantics': ["FOOD"]
                 }
    , 'answer_similarity': { 'semantics': ["FOOD"] }
    , 'level': 1
    , 'answers': 1
    , 'name': "Bodypart image to word"
    , 'points': 20
    , 'category': "TEST"
    , 'sound': False
    },
    { 'type': 'word_to_image'
    , 'filters': { 'from_language': 'sma', 'to_language': 'img'
                 , 'semantics': ["FOOD"]
                 }
    , 'answer_similarity': { 'semantics': ["FOOD"] }
    , 'level': 3
    , 'answers': 4
    , 'points': 100
    , 'category': "TEST"
    , 'sound': True
    },

]
