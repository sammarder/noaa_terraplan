import boto3
import zipfile
import io
import os
from datetime import datetime

# Initialize clients
s3 = boto3.client('s3')
ssm = boto3.client('ssm')

def move(source, bucket):
    file_name = source.split('/')[-1]
    destination_key = f"finished_archive/{file_name}"
    
    copy_source = {'Bucket': bucket, 'Key': source}

    try:
        s3.copy_object(
            Bucket=bucket, 
            CopySource=copy_source, 
            Key=destination_key
        )
        print(f"Copied {source} to {destination_key}")
        
        s3.delete_object(Bucket=bucket, Key=source)
        print(f"Deleted original: {source}")
        
    except Exception as e:
        print(f"Error moving file: {e}")
        raise

def get_ssm_value(parameter_name):
    response = ssm.get_parameter(
        Name=parameter_name
    )
    return response['Parameter']['Value']
    
def clear_archive(keys, bucket):
    for file in keys:
        s3.delete_object(Bucket=bucket, Key=file)

def lambda_handler(event, context):
    now = datetime.now()
    key = "finished_archive/glued_" + now.strftime("%Y-%m-%d") + ".zip"
    bucket_name = get_ssm_value("/noaa/s3/bucket_name")
    #TODO finish out logic, right now it creates an archive and stores it, I want it to remove the jsonl
    prefix = "extracted_data/"
    
    s3_folder = s3.list_objects_v2(Bucket = bucket_name, Prefix = prefix)
    
    file_keys = [f['Key'] for f in s3_folder.get('Contents', [])]
    
    zip_buffer = io.BytesIO()
    
    with zipfile.ZipFile(zip_buffer, "a", zipfile.ZIP_DEFLATED, False) as zip_file:
        for file in file_keys:
            response = s3.get_object(bucket_name, file)
            zip_buffer = writestr(file_key, response['Body'].read())
            
    zip_buffer.seek(0)
    s3.put_object(Bucket = bucket, key = key, Body=zip_buffer.getvalue())
    
    clear_archive(file_keys, bucket)

    return {
        'statusCode': 200,
        'body': "test success"
    }