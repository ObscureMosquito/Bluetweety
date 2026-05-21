TARGET := iphone:clang:7.0:5.0
ARCHS = armv7 armv7s arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AccountsdHelper

AccountsdHelper_FILES = Tweak.x
AccountsdHelper_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk