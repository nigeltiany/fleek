.PHONY: release ios

release:
	-rm -R ./.obf
	flutter clean
	flutter build appbundle --obfuscate --split-debug-info=./.obf

ios:
	flutter clean \
	&& \
	mv ~/Development/flutter/bin/cache/artifacts/engine/ios \
	~/Development/flutter/bin/cache/artifacts/engine/ios-RESTOREME \
	&& \
	cp -r ~/Development/flutter/bin/cache/artifacts/engine/ios-release \
	~/Development/flutter/bin/cache/artifacts/engine/ios \
	&& \
	flutter build ios --release -v --obfuscate --split-debug-info=./.obf \
	&& \
	xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphoneos \
	-configuration Release archive -archivePath \
	~/Desktop/fleek/build/Runner.xcarchive \
	&& \
 	rm -rf ~/Development/flutter/bin/cache/artifacts/engine/ios \
	&& \
	mv ~/Development/flutter/bin/cache/artifacts/engine/ios-RESTOREME \
	~/Development/flutter/bin/cache/artifacts/engine/ios