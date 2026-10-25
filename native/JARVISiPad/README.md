# JARVIS for iPad — native iPadOS starter

This folder is a native SwiftUI iPadOS app scaffold. It is **not** a website, Safari shortcut, or PWA.

## Current implementation
- Native SwiftUI chat UI designed for iPad.
- Ukrainian speech recognition through Apple's Speech framework.
- Ukrainian spoken responses through AVSpeechSynthesizer.
- Gemini API chat requests.
- Gemini API key stored in iOS Keychain.
- Dark JARVIS-inspired appearance.

## Important differences from Windows
The Windows app uses PySide6, Windows-only commands, SpeechRecognition/PyAudio, and desktop audio tooling. Those parts cannot be copied directly to iPadOS. This native version is a first port foundation; Windows automation, background wake-word listening, voice effects, and some AI/local functions still need dedicated iPadOS implementations.

## Build
Requires macOS with Xcode 15+ and XcodeGen. From this directory:
    brew install xcodegen
    xcodegen generate
    xcodebuild -project JARVISiPad.xcodeproj -scheme JARVISiPad -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

The simulator build does not produce an installable signed iPad app. Installing on a physical iPad requires a signing/provisioning route, for example Xcode with an Apple account or a compatible cloud Mac build. A paid Apple Developer membership is not always required for personal testing, but free signing has restrictions and needs periodic renewal.

## API key
On first use, open Settings and enter a Gemini API key. It is stored in Keychain on the device. Do not commit API keys or .env files to GitHub. Gemini API use may incur separate charges.
