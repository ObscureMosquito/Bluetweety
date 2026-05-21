TARGET := iphone:clang:7.0:5.0
ARCHS = armv7 armv7s arm64

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = BlueTweetyPreferences

BlueTweetyPreferences_FILES = BTRootListController.m
BlueTweetyPreferences_FRAMEWORKS = UIKit
BlueTweetyPreferences_PRIVATE_FRAMEWORKS = Preferences
BlueTweetyPreferences_INSTALL_PATH = /Library/PreferenceBundles
BlueTweetyPreferences_CFLAGS = -fobjc-arc
BlueTweetyPreferences_LDFLAGS += -F$(THEOS)/sdks/iPhoneOS7.0.sdk/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/bundle.mk
