TARGET := iphone:clang:latest:7.0


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AccountsdHelper

AccountsdHelper_FILES = Tweak.x
AccountsdHelper_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "systemctl unload /Library/LaunchDaemons/com.apple.accountsd.plist && systemctl load /Library/LaunchDaemons/com.apple.accountsd.plist"