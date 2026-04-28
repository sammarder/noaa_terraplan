import sys
import requests
from datetime import datetime, timedelta
import json
import argparse
from pathlib import Path

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

def getPops(properties):
    pops = []
    for key, value in properties.items():
        if isinstance(value, dict) and (value.get('qualityControl') != 'S' or value.get('value') == None):
            pops.append(key)
    return pops

parser = argparse.ArgumentParser()
parser.add_argument("--days_ago", type=int, default=1)
parser.add_argument("--page_size", type=int, default=250)
parser.add_argument("--fast_forward", type=int, default=0)
args = parser.parse_args()
daysago = args.days_ago
pageSize = args.page_size
fastforward = args.fast_forward

stationsURL = ""

if (fastforward > 0):
    page_cursor_url = f"https://api.weather.gov/stations"
    curr = 0
    while curr < fastforward:
        page_response = requests.get(page_cursor_url)
        page_data = page_response.json()
        page_cursor_url = page_data['pagination']['next']
        curr = curr + 1
    stationsURL = page_cursor_url.replace("limit=500", f"limit={pageSize}")    
else:
    stationsURL = f"https://api.weather.gov/stations?limit={pageSize}"

date = datetime.now() - timedelta(days=daysago)
midnight = date.strftime("%Y-%m-%dT00:00:00Z").replace(":", "%3A")
eod = date.strftime("%Y-%m-%dT23:59:59Z").replace(":", "%3A")
day = date.strftime("%Y-%m-%d")
year = date.strftime("%Y")
month = date.strftime("%m")

stationsResponse = requests.get(stationsURL)

if (stationsResponse.status_code != 200):
    sys.exit()

stationData = stationsResponse.json()

stations = stationData['observationStations']

for station in stations:
    stationId = station.split('/')[-1]
    stationDataUrl = f"{station}/observations/?start={midnight}&end={eod}"
    observations = requests.get(stationDataUrl)
    try:
        observationData = observations.json()
        if not "features" in observationData:
            print(observationData.keys())
            continue
        features = observationData['features']
        for feature in features:
            featureson = {"station_id": stationId, **cleanupFeature(feature)}
            directory = Path(f"data/{year}/{month}")
            directory.mkdir(parents=True, exist_ok=True)
            with open(f"data/{year}/{month}/{day}.jsonl", "a") as a:
                a.write(json.dumps(featureson) + "\n")
    except requests.exceptions.JSONDecodeError:
        print(f"Skipping station {stationId}: Received invalid JSON or empty response.")
        continue  # Move to the next station in the loop