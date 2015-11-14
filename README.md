# AnimatedBlurLabel

[![Twitter: @mkoehnke](https://img.shields.io/badge/contact-@mkoehnke-blue.svg?style=flat)](https://twitter.com/mkoehnke)
[![Version](https://img.shields.io/cocoapods/v/AnimatedBlurLabel.svg?style=flat)](http://cocoadocs.org/docsets/AnimatedBlurLabel)
[![License](https://img.shields.io/cocoapods/l/AnimatedBlurLabel.svg?style=flat)](http://cocoadocs.org/docsets/AnimatedBlurLabel)
[![Platform](https://img.shields.io/cocoapods/p/AnimatedBlurLabel.svg?style=flat)](http://cocoadocs.org/docsets/AnimatedBlurLabel)

Subclass of UILabel for animating the blurring and unblurring of text. Take a look at the demo project to see how to use it.

<img src="https://raw.githubusercontent.com/mkoehnke/AnimatedBlurLabel/master/Resources/AnimatedBlurLabel.gif">

# Installation

## CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate the AnimatedBlurLabel into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

pod 'AnimatedBlurLabel'
```

Then, run the following command:

```bash
$ pod install
```

## Manually
Copy the **AnimatedBlurLabel.swift** file to your Swift project, add it to a target and you're good to go.

# Usage
The easiest way to get started is to add the AnimatedBlurLabel as a custom label in your Storyboard. After that, you can set properties like animation duration or blur radius in code:

```swift
blurLabel.animationDuration = 1.0
blurLabel.blurRadius = 30.0
```

In order to blur and unblur the label's text, you simply call the following method:

```swift
func setBlurred(blurred: Bool, animated: Bool, completion: ((finished : Bool) -> Void)?)
```

# Author
Mathias Köhnke [@mkoehnke](http://twitter.com/mkoehnke)

# License
AnimatedBlurLabel is available under the MIT license. See the LICENSE file for more info.

# Recent Changes
The release notes can be found [here](https://github.com/mkoehnke/AnimatedBlurLabel/releases).
