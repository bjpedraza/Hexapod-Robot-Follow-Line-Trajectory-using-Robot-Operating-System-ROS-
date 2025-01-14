#! /usr/bin/python3
#from mpu6050 import mpu6050
import rospy
from std_msgs.msg import String

def callback(data):
        rospy.loginfo(rospy.get_caller_id() + "I heard %s", data.data)

def listener():
        rospy.init_node('listener', anonymous=True)
        rospy.Subscriber("Axis", String, callback)
        
        # keeps python from exiting until this node is stopped
        rospy.spin()


if __name__ == '__main__':
        listener()