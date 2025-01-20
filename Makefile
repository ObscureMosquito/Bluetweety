TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BlueTweety

BlueTweety_FILES = Tweak.x
BlueTweety_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += AccountsdHelper
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "systemctl unload /Library/LaunchDaemons/com.apple.accountsd.plist && systemctl load /Library/LaunchDaemons/com.apple.accountsd.plist"