TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = com.atebits.Tweetie2


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = twitteruploadhelper

twitteruploadhelper_FILES = Tweak.x
twitteruploadhelper_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
