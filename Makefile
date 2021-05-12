bump:
	docker run --rm -it -v ${CURDIR}:/app -w /app treeder/bump --filename pubspec.yaml bump

publish: bump
	flutter pub publish -f
	git commit -am "new version"
	git push

.PHONY: dep build docker release install test backup deploy publish bump
