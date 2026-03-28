import sys
import requests
from datetime import datetime, timedelta
import json

def cleanupFeature(feature):
    feature.pop('geometry')
    feature.pop('type')
    clean_properties = cleanupProperties(feature['properties'])
    del feature['properties']
    return {**feature, **clean_properties}

def cleanupProperties(properties):
    properties.pop('@id')
    type = properties.pop('@type')
    properties['type'] = type
    remove = getPops(properties)
    flattened = {}
    for top_key, value in properties.items():
        if isinstance(value, dict):
            for low_key, low_value in value.items():
                flattened[f"{top_key}_{low_key}"] = low_value
            if not (top_key in remove):
                remove.append(top_key)
    for r in remove:
        del properties[r]
    return {**properties, **flattened}
    
def get_int_arg(index, default=0):
    try:
        # 1. Grab the argument from the list
        raw_value = sys.argv[index]
        # 2. Try to convert it
        return int(raw_value)
    except IndexError:
        # Case: The user didn't provide enough arguments
        print(f"No argument at index {index}, using default: {default}")
        return default
    except ValueError:
        # Case: The argument exists but isn't a valid integer
        print(f"Argument '{raw_value}' is not a number, using default: {default}")
        return default

def getPops(properties):
    pops = []
    for key, value in properties.items():
        if isinstance(value, dict) and (value.get('qualityControl') != 'S' or value.get('value') == None):
            pops.append(key)
    return pops

daysago = get_int_arg(1) if len(sys.argv) > 1 else 0

stationsURL = "https://api.weather.gov/stations?limit=200"
date = datetime.now() - timedelta(days=daysago)
midnight = date.strftime("%Y-%m-%dT00:00:00Z").replace(":", "%3A")
day = date.strftime("%Y-%m-%d")

stationsResponse = requests.get(stationsURL)

if (stationsResponse.status_code != 200):
    sys.exit()

stationData = stationsResponse.json()

stations = stationData['observationStations']

for station in stations:
    stationId = station.split('/')[-1]
    stationDataUrl = f"{station}/observations/?start={midnight}&limit=25"
    observations = requests.get(stationDataUrl)
    observationData = observations.json()
    features = observationData['features']
    for feature in features:
        featureson = {"station_id": stationId, **cleanupFeature(feature)}
        with open(f"{day}.jsonl", "a") as a:
            a.write(json.dumps(featureson) + "\n")
    