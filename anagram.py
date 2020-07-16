from urllib.parse import unquote_plus
import uuid
import sys
import os
import boto3
from collections import defaultdict


### Helper functions
# This function takes two strings s1 and s2,
# returns whether they are anagrams.
# (str, str) -> bool
def is_anagram(s1, s2):
    # Check if the length of two strings are equal
    if len(s1) != len(s2):
        return False

    # Case insensitive check for anagrams
    s1 = s1.lower()
    s2 = s2.lower()

    # Create default dictionary for default zero character count
    char_count = defaultdict(lambda: 0)
    # For all the characters in s1, populate char_count dictionary
    for c in s1:
        char_count[c] += 1

    # Now, check whether they are anagrams
    for c in s2:
        if char_count[c] == 0:
            return False
        char_count[c] -= 1

    return True

### Handler function

s3_client = boto3.client('s3')

# Lambda handler
def anagram_lambda_handler(event, context):
    for record in event['Records']:
        # Get the name of the bucket
        bucket = record['s3']['bucket']['name']  
        # Get the name of the file
        key = unquote_plus(record['s3']['object']['key'])
        
        # We need to show a unique download path for newly uploaded anagram files
        tmpkey = key.replace('/', '')
        download_path = '/tmp/{}{}'.format(uuid.uuid4(), tmpkey)
        s3_client.download_file(bucket, key, download_path)
        
        # After download, open and parse the file and
        f = open(download_path, 'r')
        for l in f:
            words = l.rstrip('\n').split(',')
            print('is_anagram({word_0}, {word_1}) = {res}'
                .format(word_0=words[0], word_1=words[1], res=is_anagram(words[0], words[1])))