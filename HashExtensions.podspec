Pod::Spec.new do |s|
  s.name         = "HashExtensions"
  s.version      = "1.0.0"
  s.summary      = "Extensions for crypto hashes in NSData and NSString."
  s.description  = <<-DESC
                   Extensions for crypto hashes in NSData and NSString
                   
                   Supported hashes:
                   - MD2
                   - MD4
                   - MD5
                   - SHA1
                   - SHA224
                   - SHA256
                   - SHA384
                   - SHA512
                   DESC

  s.homepage     = "https://github.com/anfema/amp-ios-client"
  s.license      = { :type => "BSD", :file => "HashExtensions/LICENSE.txt" }
  s.author             = { "Johannes Schriewer" => "j.schriewer@anfe.ma" }
  s.social_media_url   = "http://twitter.com/dunkelstern"

  s.ios.deployment_target = "8.4"
  s.osx.deployment_target = "10.10"

  s.source       = { :git => "git@github.com:anfema/amp-ios-client.git", :branch => "feature/j.schriewer/cocoapods" }

  s.source_files  = "HashExtensions/HashExtensions/*.{h,m}"
  s.public_header_files = "HashExtensions/HashExtensions/*.h"
  s.private_header_files = "HashExtensions/HashExtensions/Internal.h"
end
