# MINIKeyboard — xcodebuild 한 줄을 외우지 않기 위한 메뉴. 로직은 없다.

PROJECT := MINIKeyboard.xcodeproj
SCHEME  := MINIKeyboard
DEST    := platform=macOS

.PHONY: help test package-test build check
.DEFAULT_GOAL := help

help:  ## 사용 가능한 명령 보기
	@awk 'BEGIN{FS=":.*## "} /^[a-z][a-z-]*:.*## /{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}' $(MAKEFILE_LIST)

# 테스트 호스트는 앱 자신이다 — 테스트하는 동안 앱이 떠서 평소처럼 키보드를 찾는다.
test:  ## 단위 테스트
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' test

# 패키지(Domain · DataLayer · Presentation)의 테스트. 앱을 띄우지 않고 키보드도 열지 않는다 — 장치는 가짜와
# 시뮬레이터로 대신한다.
package-test:  ## 패키지 테스트 (앱을 띄우지 않는다)
	swift test --package-path Packages/MINIKeyboardKit

build:  ## 빌드. warnings-as-errors 라 경고 하나가 곧 실패다
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' build

# Xcode 는 서명 설정을 UI 에서 건드리면 DEVELOPMENT_TEAM 을 프로젝트 파일에 도로 써
# 넣는다. 그러면 팀 ID 가 저장소에 들어가고, xcconfig 보다 우선하므로 각자의 팀을
# 쓰던 사람의 빌드도 깨진다. 커밋 전에 이걸 돌린다.
check:  ## 커밋해서는 안 될 값이 프로젝트 파일에 들어갔는지 본다
	@if grep -q 'DEVELOPMENT_TEAM' $(PROJECT)/project.pbxproj; then \
		echo "DEVELOPMENT_TEAM 이 $(PROJECT) 안에 있다. 지우고 Signing.xcconfig 에 둘 것:" >&2; \
		grep -n 'DEVELOPMENT_TEAM' $(PROJECT)/project.pbxproj >&2; \
		exit 1; \
	fi
	@echo "프로젝트 파일 깨끗"
