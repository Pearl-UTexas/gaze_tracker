#!/usr/bin/env python
import rospy
import sys
import cv2
import face_recognition
import time
from std_msgs.msg import String, Float32MultiArray, Bool, Float32
from cv_bridge import CvBridge
from sensor_msgs.msg import Image
from rail_object_detector.msg import Detections
from gaze_tracker.srv import GazePredict
from gaze_tracker.msg import GazeTopic, FaceDetectionTopic

class GazePredictWrapper:
    """
    Class description for ROS Node to inteface with Gaze Prediction deep network service in MATLAB
    
    Attributes:
        face_locations: Array of current face locations
        gaze_srv: Proxy for matlab deep network
        obj_bridge_pub: Publisher to "object_detector_bridge" topic
        object_locations: array of current yolo object locations
        rail_srv: Proxy for YOLO service call
        rgb_image: Image topic for processing frames
        use_yolo: Enable YOLO processing in line
    """

    def __init__(self, image_topic, use_yolo=False):
        """
        Initializes connections to MATLAB service, image, face detection and YOLO detection topic
        Args:
            image_topic (String): ROS Topic name for image stream
            use_yolo (bool, optional): Enable YOLO processing in parallel
        """
        print "Starting GazePredictWrapper Init"
        self.rgb_image, self.face_locations, self.object_locations = None, None, []
        self.use_yolo = use_yolo

        if self.use_yolo:
            print "GazePredictWrapper using YOLO"
            rospy.Subscriber('detector_node/detections', Detections, self.update_objects)

        rospy.wait_for_service('gaze_predict')
        self.gaze_srv = rospy.ServiceProxy('gaze_predict', GazePredict)
        self.obj_bridge_pub = rospy.Publisher(
            "object_detector_bridge", GazeTopic)
        rospy.Subscriber(image_topic, Image, self.process_img, queue_size=1, buff_size=52428800)
        rospy.Subscriber("face_detections",
                         FaceDetectionTopic, self.update_face)

        rospy.sleep(5)

        print "Finished GazePredictWrapper Init"

    def process_img(self, rgb):
        """
        Callback function for image topic, publish gaze predictions if there is a 
        face in the frame.
        Args:
            rgb: image callback
        """
        if self.face_locations:
            self.rgb_image = rgb
            gaze_response = self.gaze_srv(
                rgb.header, rgb, self.face_locations, self.object_locations)
            self.publish_data(gaze_response, rgb.header.stamp)


    def publish_data(self, msg, stamp):
        """
        Method for publishing gaze prediction/YOLO outputs to detector bridge topic
        Args:
            msg: Response from MATLAB network
            stamp: Timestamp to put in message head
        """
        coordinates, mutual = msg.coordinates.data, msg.mutual.data

        if (len(coordinates) > 0):
            adjusted_coordinates = map(lambda x: int(x)*2, coordinates)
            coordinate_array = Float32MultiArray(data=adjusted_coordinates)
            mutual_bool = Bool(data=mutual)
            mutual_value_msg = Float32(data=msg.mutual_value.data)
            nearest_object_msg = String(data=msg.nearest_object.data)

            topic_msg = GazeTopic(coordinates=coordinate_array, mutual=mutual_bool,mutual_value=mutual_value_msg, 
                                  nearest_object=nearest_object_msg, frame_count=msg.frame_count, yolo_objects=self.object_locations)

            topic_msg.header.stamp = stamp
            self.obj_bridge_pub.publish(topic_msg)

    def update_face(self, msg):
        """
        Callback function for face detector
        Args:
            msg: FaceDetectionTopic.msg
        """
        self.face_locations = msg.faces

    def update_objects(self, msg):
        """
        Callback function for YOLO object detector
        Args:
            msg: Detections.msg from rail_object_detector
        """
        self.object_locations = msg.objects


def main():
    use_yolo = rospy.get_param("/object_detector_bridge/use_yolo")
    image_topic = rospy.get_param("/image_topic_name")
    obj = GazePredictWrapper(image_topic=image_topic,
                             use_yolo=use_yolo)

if __name__ == '__main__':
    rospy.init_node('gaze_predict_wrapper', anonymous=True)
    main()
    while not rospy.is_shutdown():
        rospy.spin()
