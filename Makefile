TARGET := iphone:clang:latest:7.0


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RedirectVoWiFiTweak

INSTALL_TARGET_PROCESSES=CommCenter

RedirectVoWiFiTweak_FILES = Tweak.x
RedirectVoWiFiTweak_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
