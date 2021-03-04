.PHONY: release ios

release:
	-rm -R ./.obf
	flutter clean
	flutter build appbundle --obfuscate --split-debug-info=./.obf

ios:
	flutter clean \
	&& \
	flutter build ios --release -v --obfuscate --split-debug-info=./.obf \
	&& \
	xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphoneos \
	-configuration Release archive -archivePath \
	~/Desktop/fleek/build/Runner.xcarchive;