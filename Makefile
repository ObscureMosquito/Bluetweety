TARGET := iphone:clang:latest:5.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = armv7 armv7s arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BlueTweety

BlueTweety_FILES = Tweak.x
BlueTweety_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += AccountsdHelper
SUBPROJECTS += BlueTweetyPreferences
SUBPROJECTS += twitteruploadhelper
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "systemctl kickstart -k /Library/LaunchDaemons/com.apple.accountsd.plist && systemctl kickstart -k /Library/LaunchDaemons/com.apple.accountsd.plist && systemctl kickstart -k /Library/LaunchDaemons/com.apple.twitterd.plist"
