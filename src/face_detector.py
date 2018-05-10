#!/usr/bin/env python
import rospy
import sys
import cv2
from std_msgs.msg import Float32MultiArray
from cv_bridge import CvBridge
from sensor_msgs.msg import Image
from object_detector.msg import FaceDetectionTopic
import face_recognition


class FaceDetector:
  def __init__(self, model_name, basename='frontal-face', tgtdir='.', min_height_dec=20, min_width_dec=20, min_height_thresh=50, min_width_thresh=50):
    print "Starting Init for Face Detector"

    self.face_detector_pub = rospy.Publisher("face_detections",FaceDetectionTopic)
    rospy.sleep(2)
    self.bridge = CvBridge()
    self.rgb_image = None
    self.depth_image = None

    self.min_height_dec = min_height_dec
    self.min_width_dec = min_width_dec
    self.min_height_thresh = min_height_thresh
    self.min_width_thresh = min_width_thresh
    self.tgtdir = tgtdir
    self.basename = basename
    self.face_cascade = cv2.CascadeClassifier(model_name)

    image_topic = rospy.get_param("/image_topic_name")

    detection_sub = rospy.Subscriber(image_topic,Image, self.callback, queue_size=1, buff_size=52428800)

    rospy.sleep(5)

    print "Finished Init for Face Detector"


  def callback(self,rgb):
    """Callback from image topic
    
    Args:
        rgb: image message
    """
    self.rgb_image = rgb

    cv_image = self.bridge.imgmsg_to_cv2(rgb, "bgr8")

    faces = self.detect_faces(cv_image)
    msg = FaceDetectionTopic()
    msg.faces = faces
    self.face_detector_pub.publish(msg)


  def detect_faces(self, img):
    """Uses face recognition and image to detect faces
    
    Args:
        img: opencv image
    
    Returns:
        Float32MultiArray: face locations
    """
    faces = face_recognition.face_locations(img, number_of_times_to_upsample=1, model="cnn")

    multi_array = []
    for face in faces:
      face_array = Float32MultiArray()
      face_array.data = face
      multi_array.append(face_array)

    return multi_array

def main():
  """Instantiate FaceDetector class with model path
  """
  obj = FaceDetector(model_name='/usr/share/opencv/haarcascades/haarcascade_frontalface_default.xml')

if __name__ == '__main__':
  rospy.init_node('face_detector', anonymous=True)
  main()
  while not rospy.is_shutdown():
    rospy.spin()
