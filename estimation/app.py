import tensorflow as tf
import numpy as np
import cv2
import json
import boto3
from datetime import datetime
import os

def calculate_coordinates(results, image_height, image_width, threshold=0.15):
  coordinates = []
  person_count, _, __, ___ = results.shape
  for i in range(person_count):
    coordinates_x = results[0, i, :, 1]
    coordinates_y = results[0, i, :, 0]
    scores = results[0, i, :, 2]
    coordinates_absolute = np.stack(
        [image_width * np.array(coordinates_x), image_height * np.array(coordinates_y)], axis=-1)
    filtered_coordinates = coordinates_absolute[
        scores > threshold, :]
    coordinates.append(filtered_coordinates)

  if coordinates:
    resulting_coordinates = np.concatenate(coordinates, axis=0)
  else:
    resulting_coordinates = np.zeros((0, 17, 2))

  return resulting_coordinates

s3_client = boto3.client('s3')

bucket = os.environ["BUCKET_NAME"]

interpreter = tf.lite.Interpreter(model_path="movenet.tflite")
interpreter.allocate_tensors()

def process_frame(frame):
    start_time = datetime.now() 

    img = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    tensor_image = tf.convert_to_tensor(img, dtype=tf.uint8)

    input_image = tf.expand_dims(tensor_image, axis=0)

    input_image = tf.image.resize_with_pad(input_image, 224, 224)
            
    input_image = tf.cast(input_image, dtype=tf.uint8)
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    interpreter.set_tensor(input_details[0]['index'], input_image.numpy())
    interpreter.invoke()

    results = interpreter.get_tensor(output_details[0]['index'])

    coordinates = calculate_coordinates(results, 224, 224)

    time_elapsed = datetime.now() - start_time

    print('Time elapsed (hh:mm:ss.ms) {}'.format(time_elapsed))

    return coordinates

def handler(event, _):
    print(event)
    body = event["Records"][0]["body"]

    body = json.loads(body)

    prefix = body["responsePayload"]["prefix"]

    results_bottom = body["responsePayload"]["results_bottom"]
    results_top = body["responsePayload"]["results_top"]

    key = prefix + ".mp4"

    url = s3_client.generate_presigned_url('get_object',
                                       Params = {'Bucket': bucket, 'Key': key}, 
                                       ExpiresIn = 600)
    
    cap = cv2.VideoCapture(url)

    coordinates_bottom = []

    coordinates_top = []

    current_frame = 0

    while(cap.isOpened()):

        ret, frame = cap.read()
        if(ret == True):
            
            for value in results_bottom:
               if (value - current_frame).abs() < 5:
                   coordinates = process_frame(frame)
                   coordinates_bottom.append((current_frame, coordinates))
            
            for value in results_top:
               if (value - current_frame).abs() < 5:
                   coordinates = process_frame(frame)
                   coordinates_top.append((current_frame, coordinates))
            
        current_frame += 1

    return {
      "statusCode": 200,
      "coordinates_top": coordinates_top,
      "coordinates_bottom": coordinates_bottom
    }

