import json
import requests

r = requests.get('http://localhost:8080/pets')
input_json = r.text

input_dict = json.loads(input_json)

for pet in input_dict:
    if (pet['name'] == 'Frieda'):
        requests.delete("http://localhost:8080/pets/" + pet['_id'])
