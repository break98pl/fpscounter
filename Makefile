export ARCHS = arm64 arm64e
export TARGET = iphone:clang:14.5:7.0
export FINALPACKAGE=1
export THEOS_DEVICE_IP=192.168.1.30

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FPSCounter
FPSCounter_FILES = Tweak.xm KMCGeigerCounter.xm
FPSCounter_FRAMEWORKS = UIKit QuartzCore SpriteKit

include $(THEOS_MAKE_PATH)/tweak.mk

