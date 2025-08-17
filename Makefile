TARGET := iphone:clang:2.0:2.0
INSTALL_TARGET_PROCESSES = TestProject
ARCHS = armv6

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = TestProject

TestProject_FILES = main.m AppDelegate.m MainTableController.m
TestProject_FRAMEWORKS = UIKit CoreGraphics
TestProject_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/application.mk
