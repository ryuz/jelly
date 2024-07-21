import grpc
from grpc.tools import protoc

protoc.main(
    (
        '',
        '-I../protos',
        '--python_out=.',
        '--grpc_python_out=.',
        'camera_control.proto'
    )
)

import camera_control_pb2
import camera_control_pb2_grpc


import numpy as np
import cv2


channel = grpc.insecure_channel('kria:50051')
stub = camera_control_pb2_grpc.CameraControlStub(channel)

stub.SetAoi(camera_control_pb2.SetAoiRequest(id=1, width=640, height=480, x=-1, y=-1))
stub.Open(camera_control_pb2.OpenRequest(id=1))

img_resp = stub.GetImage(camera_control_pb2.GetImageRequest(id=1))
img = np.frombuffer(img_resp.image, dtype=np.uint8, count=len(img_resp.image)).reshape(img_resp.height, img_resp.width, -1)

cv2.imshow("img", img)
cv2.waitKey()
