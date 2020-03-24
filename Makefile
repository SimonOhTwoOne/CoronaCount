INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e
VALID_ARCHS = arm64 arm64e

SYSROOT=$(THEOS)/sdks/iPhoneOS13.0.sdk

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CoronaCount

CoronaCount_FILES = Tweak.xm
CoronaCount_CFLAGS = -fobjc-arc
CoronaCount_EXTRA_FRAMEWORKS +=  Cephei
SUBPROJECTS += coronapref
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
