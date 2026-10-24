# ---------------------------------------------------------------------------
#  OpenTune 9 - cliente de YouTube Music para iOS 9 (armv7 / iPad mini 1)
#
#  Port nativo del OpenTune original (Arturo254, GPL-3.0) a Objective-C/UIKit.
#  Compila con Theos y se firma ad-hoc con ldid.
#
#  Compilar:  make clean && make package FINALPACKAGE=1 PACKAGE_FORMAT=ipa
# ---------------------------------------------------------------------------

TARGET = iphone:clang:9.3:9.0
ARCHS = armv7
PACKAGE_FORMAT = ipa

# La app usa APIs de iOS 9 ya obsoletas y queremos avisos, no errores.
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = OpenTune9

OpenTune9_FILES = \
	main.m \
	AppDelegate.m \
	OTTheme.m \
	OTItem.m \
	OTImageCache.m \
	OTInnertube.m \
	OTStore.m \
	OTPlayer.m \
	OTLyrics.m \
	OTDownloads.m \
	OTComponents.m \
	OTRootViewController.m \
	OTFeedViewController.m \
	OTHomeViewController.m \
	OTSearchViewController.m \
	OTLibraryViewController.m \
	OTMoodViewController.m \
	OTCollectionViewController.m \
	OTPlayerViewController.m \
	OTSettingsViewController.m

OpenTune9_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore AVFoundation \
	MediaPlayer CoreMedia CoreText ImageIO Security CFNetwork \
	MobileCoreServices SystemConfiguration Accelerate

OpenTune9_CFLAGS = -fobjc-arc \
	-Wno-deprecated-declarations \
	-Wno-unused-parameter \
	-Wno-nullability-completeness \
	-Wno-objc-missing-super-calls \
	-Wno-unused-variable \
	-Wno-unused-function

OpenTune9_RESOURCE_DIRS = Resources

OpenTune9_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall -9 OpenTune9 2>/dev/null || true"
