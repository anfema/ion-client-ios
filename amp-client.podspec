Pod::Spec.new do |s|
  s.name         = "amp-client"
  s.version      = "1.2.6"
  s.summary      = "AMP-Client for iOS and OS X clients."
  s.description  = <<-DESC
                   AMP-Client for iOS and OS X clients

                   Features:
                   - Fully automatic cache handling
                   - React style API
                   - Fully async
                   - Full text search in content
                   - Content downloading for offline mode
                   DESC

  s.homepage     = "https://github.com/anfema/amp-ios-client"
  s.license      = { :type => "BSD", :file => "amp-client/LICENSE.txt" }
  s.author             = { "Johannes Schriewer" => "j.schriewer@anfe.ma" }
  s.social_media_url   = "http://twitter.com/dunkelstern"

  s.ios.deployment_target = "8.4"
  s.osx.deployment_target = "10.10"

  s.source       = { :git => "git@github.com:anfema/amp-ios-client.git", :tag => "client-1.2.6" }
  s.source_files  = "amp-client/cache/*.swift", "amp-client/communication/*.swift", "amp-client/helper/*.swift", "amp-client/model/**/*.swift", "amp-client/search/*.swift"
  
  s.framework  = "Alamofire", "DEjson", "Markdown", "HashExtensions", "html5parser"
  s.libraries  = "sqlite3"
  s.module_map = "amp-client/cocoapods.modulemap"

  s.dependency "Alamofire", "~> 3.0"
  s.dependency "DEjson", "~> 1.0"
  s.dependency "Markdown", "~> 1.0"
  s.dependency "HashExtensions", "~> 1.0"
  s.dependency "html5parser", "~> 1.0"
  s.dependency "Tarpit", "~> 1.0"
end
