import boto3, botocore
STORAGE_ENDPOINT = 'http://0.0.0.0:8080'
STORAGE_ACCESSKEY = 'testuser2'
STORAGE_SECRETKEY = 'Passw0rd'
from botocore.client import Config
session = boto3.Session()
s3 = session.resource('s3', endpoint_url=STORAGE_ENDPOINT, aws_access_key_id='testuser2', aws_secret_access_key='Passw0rd', config=Config(signature_version='s3v4'))
bucket = s3.create_bucket(Bucket='bucket14')
#bucket
#s3.Bucket(name='bucket11')
for obj in bucket.objects.all():
    print(obj)
data = open('3M', 'rb')
bucket.put_object(Key='3M', Body=data)
#s3.Object(bucket_name='bucket11', key='test.txt')
