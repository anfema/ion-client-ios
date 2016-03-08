Pod::Spec.new do |s|
  s.name         = "ion-client"
  s.version      = "2.0.0"
  s.summary      = "ION-Client for iOS and OS X clients."
  s.description  = <<-DESC
                   ION-Client for iOS and OS X clients

                   Features:
                   - Fully automatic cache handling
                   - React style API
                   - Fully async
                   - Full text search in content
                   - Content downloading for offline mode
                   DESC

  s.homepage     = "https://github.com/anfema/amp-ios-client"
  s.license      = { :type => "BSD", :file => "ion-client/LICENSE.txt" }
  s.author             = { "Johannes Schriewer" => "j.schriewer@anfe.ma" }
  s.social_media_url   = "http://twitter.com/dunkelstern"

  s.ios.deployment_target = "8.4"
  s.osx.deployment_target = "10.10"

  s.source       = { :git => "git@github.com:anfema/amp-ios-client.git", :tag => "1.4.8" }
  s.source_files  = "ion-client/cache/*.swift", "ion-client/communication/*.swift", "ion-client/helper/*.swift", "ion-client/model/**/*.swift", "ion-client/search/*.swift"
  
  s.framework  = "Alamofire", "DEjson", "Markdown", "HashExtensions", "html5tokenizer", "Tarpit"
  s.libraries  = "sqlite3"
  s.module_map = "ion-client/cocoapods.modulemap"

  s.dependency "Alamofire", "~> 3.0"
  s.dependency "DEjson", "~> 1.0"
  s.dependency "Markdown", "~> 1.0"
  s.dependency "HashExtensions", "~> 2.0"
  s.dependency "html5tokenizer", "~> 1.0"
  s.dependency "Tarpit", "~> 1.0"
end