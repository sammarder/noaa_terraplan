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
    print("Starting the archiving process")
    target_key = f"finished_archive/glued_{now.strftime('%Y-%m-%d')}.zip"
    bucket_name = get_ssm_value("/noaa/s3/bucket_name")
    prefix = "extracted_data/"
    
    # 1. Get file list (Note: This only gets first 1000 files)
    response = s3.list_objects_v2(Bucket=bucket_name, Prefix=prefix)
    file_keys = [obj['Key'] for obj in response.get('Contents', []) if obj['Key'] != prefix]
    print("Found " + len(file_keys) + " files")

    if not file_keys:
        return {'statusCode': 200, 'body': 'No files to archive'}

    zip_buffer = io.BytesIO()
    
    # 2. Corrected Zip Logic
    with zipfile.ZipFile(zip_buffer, "a", zipfile.ZIP_DEFLATED) as zip_file:
        for file_key in file_keys:
            # Get the object from S3
            s3_obj = s3.get_object(Bucket=bucket_name, Key=file_key)
            # Use only the filename (not the full path) inside the zip
            inner_file_name = file_key.split('/')[-1]
            zip_file.writestr(inner_file_name, s3_obj['Body'].read())
            
    print("Finished buffering the zip file")
            
    # 3. Upload the Archive
    zip_buffer.seek(0)
    s3.put_object(
        Bucket=bucket_name, 
        Key=target_key, 
        Body=zip_buffer.getvalue()
    )
    
    # 4. Cleanup (Ensure clear_archive is defined to delete the list of keys)
    clear_archive(file_keys, bucket_name)

    return {
        'statusCode': 200,
        'body': f"Archived {len(file_keys)} files to {target_key}"
    }