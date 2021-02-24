.PHONY: release

release:
	-rm -R ./.obf
	flutter clean
	flutter build appbundle --obfuscate --split-debug-info=./.obf