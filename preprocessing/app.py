import json
import cv2
import boto3
import numpy as np
import torch
import torchvision
import os
from datetime import datetime

s3_client = boto3.client('s3')

output_bucket = 'smart-fit-processed-images'

device = "cpu"
model = torch.jit.load('DeepLabResNet.pth').eval().to(device)

def handler(event, _):
    key = event["Records"][0]["s3"]["object"]["key"]
    bucket = event["Records"][0]["s3"]["bucket"]["name"]

    print(key)

    type = key.split('/')[1]

    url = s3_client.generate_presigned_url('get_object',
                                       Params = {'Bucket': bucket, 'Key': key}, 
                                       ExpiresIn = 600)

    imagenet_stats = [[0.485, 0.456, 0.406], [0.485, 0.456, 0.406]]
    preprocess = torchvision.transforms.Compose([torchvision.transforms.ToTensor(),
                                                torchvision.transforms.Normalize(mean = imagenet_stats[0],
                                                                                  std  = imagenet_stats[1])])
    
    cap = cv2.VideoCapture(url)

    current_frame = 0

    while(cap.isOpened()):

        ret, frame = cap.read()
        if(ret == True):

            start_time = datetime.now() 

            img = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            input_tensor = preprocess(img).unsqueeze(0)
            input_tensor = input_tensor.to(device)

            with torch.no_grad():
                output = model(input_tensor)["out"][0]
                output = output.argmax(0)

            result = output.cpu().numpy()

            mask = result != 0
            mask = np.repeat(mask[:, :, np.newaxis], 3, axis = 2)

            folder_name = key.split('.mp4')[0]

            image_name =  folder_name + '/' + str(current_frame) + '.png'

            image_string = cv2.imencode('.png', mask * 255)[1].tostring()

            time_elapsed = datetime.now() - start_time

            print('Time elapsed (hh:mm:ss.ms) {}'.format(time_elapsed))

            s3_client.put_object(
                Bucket=output_bucket,
                Key=image_name,
                Body=image_string
            )
        else:
            return {
                'statusCode': 200,
                'prefix': folder_name,
                'type': type
            }
            
        current_frame += 1

    return {
        'statusCode': 200,
        'prefix': folder_name,
        'type': type
    }
    