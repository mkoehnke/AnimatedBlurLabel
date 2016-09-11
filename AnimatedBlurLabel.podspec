Pod::Spec.new do |s|

  s.name         = "AnimatedBlurLabel"
  s.version      = "1.5.0"
  s.summary      = "Subclass of UILabel for animating the blurring and unblurring of text in iOS"

  s.description  = <<-DESC
                   Label for animating the blurring and unblurring of text in iOS — written in Swift 
                   DESC

  s.homepage     = "https://github.com/mkoehnke/AnimatedBlurLabel"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  
  s.author       = "Mathias Köhnke"
  
  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/mkoehnke/AnimatedBlurLabel.git", :tag => s.version.to_s }

  s.source_files  = "AnimatedBlurLabel", "AnimatedBlurLabel/**/*.{swift}"
  s.exclude_files = "Classes/Exclude"
  
  s.requires_arc = true

end
