# AsyncScheduler [![Swift](https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat)](https://developer.apple.com/swift/) ![Platforms](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-%23989898)
An experimental concurrent scheduler for Combine that uses the new Swift concurrency features (`async/await`, `Task`)

**Latest release**: 18.11.2021 • version 0.1.0

**Requirements**: iOS 15.0+ • macOS 12.0+ • tvOS 15.0+ • watchOS 8.0+ • Swift 5.1+ / Xcode 13.1+

| Swift version | Project version                                             |
| ------------- | ----------------------------------------------------------- |
| **Swift 5.1** | **v0.1.0**                                                  |

## Table of Contents
* [Usage](#usage)
* [Structure](#structure)

## <a name="usage"></a> Usage
#### [Swift Package Manager](https://github.com/apple/swift-package-manager)

**Tested with `swift build --version`: `Swift Package Manager - Swift 5.5.0`**

```swift
// swift-tools-version:5.1
dependencies: [
    .package(url: "https://github.com/T1T4N/AsyncScheduler.git", from: "0.1.0")
]
```

#### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

**Tested with `pod --version`: `1.10.0`**

```ruby
platform :osx, '12.0'
use_frameworks!

target 'MyApp' do
  pod 'AsyncScheduler', :git => "https://github.com/T1T4N/AsyncScheduler.git", :tag => "0.1.0"
end
```

## <a name="structure"></a> Structure
This is a Swift library meant to be used in reactive codebases that use [Combine](https://developer.apple.com/documentation/combine).

