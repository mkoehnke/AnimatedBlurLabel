# AnimatedBlurLabel

Subclass of UILabel for animating the blurring and unblurring of text. Take a look at the demo project to see how to use it.

<img src="https://raw.githubusercontent.com/mkoehnke/AnimatedBlurLabel/master/Resources/AnimatedBlurLabel.gif">

# Installation
Copy the **AnimatedBlurLabel.swift** file to your Swift project, add it to your target and you're good to go.

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
