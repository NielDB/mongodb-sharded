import json
import requests

file = open('config')
text = file.read().strip()

update_json = { "name": "Blafke","species": "woef","breed": "Poedel" }

r = requests.get('http://' + text + ':8080/pets')
input_json = r.text

input_dict = json.loads(input_json)

for pet in input_dict:
    if (pet['name'] == 'Frieda'):
        requests.put("http://" + text + ":8080/pets/" + pet['_id'], json = update_json)
