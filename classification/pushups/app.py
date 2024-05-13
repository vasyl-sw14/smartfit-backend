import json
import cv2
import boto3
import numpy as np
import tensorflow as tf
from tensorflow.keras.utils import load_img, img_to_array
import os
from PIL import Image
from io import BytesIO
from datetime import datetime

s3_client = boto3.client('s3')
s3 = boto3.resource('s3', region_name='ap-southeast-1')
ddb_client = boto3.resource("dynamodb")
table = ddb_client.Table('Workout-5sbf46du6jdz3l4ob3yko4tmbq-dev')

output_bucket = 'smart-fit-processed-images'

bucket = s3.Bucket(output_bucket)

loaded_model = tf.keras.models.load_model("pushup.keras")

def handler(event, _):
    print(event)
    body = event["Records"][0]["body"]

    body = json.loads(body)

    prefix = body["responsePayload"]["prefix"]

    print(prefix)

    result = s3_client.list_objects_v2(Bucket=output_bucket, Prefix=prefix)

    inference_results = []
    
    for file in result['Contents']:
        object = bucket.Object(file['Key'])
        response = object.get()
        file_stream = response['Body']
        img = Image.open(file_stream)

        res = img.resize((224, 224), Image.NEAREST)
        
        image = np.array(res, dtype=np.uint8)

        image = image / 255
        image = np.expand_dims(image, axis=0)

        stacked_image = np.vstack([image])

        classes = loaded_model.predict(stacked_image, batch_size=10)

        inference_results.append({"key": file['Key'].split("/")[3].split('.')[0], "classes": classes})

    inference_results = sorted(inference_results, key=lambda x: int(x['key']))

    indexes_top = []
    indexes_bottom = []

    for i in range(len(inference_results)):
        probability_top = inference_results[i]['classes'][0][1]
        probability_bottom = inference_results[i]['classes'][0][0]

        if probability_top > 0.6:
            indexes_top.append(i)

        if probability_bottom > 0.6:
            indexes_bottom.append(i)

    print(indexes_top)
    print(indexes_bottom)

    sequences_top = []
    sequences_bottom = []

    subarray = []

    for i, index in enumerate(indexes_top):
        if i == 0:
            subarray.append(index)
        elif index == indexes_top[i - 1] + 1:
            subarray.append(index)
        else:
            if (len(subarray) > 5):
                sequences_top.append(subarray)
            subarray = [index]

    sequences_top.append(subarray)
        
    subarray = []

    for i, index in enumerate(indexes_bottom):
        if i == 0:
            subarray.append(index)
        elif index == indexes_bottom[i - 1] + 1:
            subarray.append(index)
        else:
            if (len(subarray) > 5):
                sequences_bottom.append(subarray)
            subarray = [index]

    sequences_bottom.append(subarray)

    print(sequences_top)
    print(sequences_bottom)

    detected_top_positions = []

    for sequence in sequences_top:
        probabilities_sequence = [inference_results[i]['classes'][0][1] for i in sequence]

        detected_index = probabilities_sequence.index(max(probabilities_sequence))
        detected_top_positions.append(sequence[detected_index])
    
    print(detected_top_positions)

    detected_bottom_positions = []

    for sequence in sequences_bottom:
        probabilities_sequence = [inference_results[i]['classes'][0][0] for i in sequence]

        detected_index = probabilities_sequence.index(max(probabilities_sequence))
        detected_bottom_positions.append(sequence[detected_index])
    
    print(detected_bottom_positions)

    id = prefix.split("/")[2]

    response = table.update_item(
        Key={
            'id': id
        },
        UpdateExpression='SET results_bottom = :results_bottom, results_top = :results_top, processing_status = :processing_status',
        ExpressionAttributeValues={
            ':results_bottom': detected_bottom_positions,
            ':results_top': detected_top_positions,
            ':processing_status': 'completed'
        }
    )

    print(response)

    return {
        'statusCode': 200,
        'body': json.dumps('Success'),
        "prefix": prefix,
        "results_bottom": detected_bottom_positions,
        "results_top": detected_top_positions
    }
    