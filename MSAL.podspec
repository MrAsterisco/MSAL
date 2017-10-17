Pod::Spec.new do |s|
  s.name             = "MSAL"
  s.version          = "1.0.1"
  s.summary          = "A modified and enhanced version of the Microsoft Authentication Library (MSAL) for iOS"
  s.homepage         = "https://github.com/MrAsterisco/microsoft-authentication-library-for-objc"
  s.license          = 'MIT'
  s.author           = { "Alessio Moiso" => "a.moiso@pillohealth.com" }
  s.source           = { :git => "https://github.com/MrAsterisco/microsoft-authentication-library-for-objc.git", :tag => s.version }

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'src'

  s.frameworks = 'UIKit'
  s.module_name = 'MSAL'
end