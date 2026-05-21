TARGET := iphone:clang:7.0:5.0
ARCHS = armv7 armv7s arm64

INSTALL_TARGET_PROCESSES = com.atebits.Tweetie2


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = twitteruploadhelper

twitteruploadhelper_FILES = Tweak.x
twitteruploadhelper_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
