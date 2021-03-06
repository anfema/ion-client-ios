Pod::Spec.new do |s|
  s.name         = "ion-client"
  s.version      = "6.2.0"
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

  s.homepage     = "https://github.com/anfema/ion-client-ios"
  s.license      = { :type => "BSD", :file => "ion-client/LICENSE.txt" }
  s.author             = { "Johannes Schriewer" => "j.schriewer@anfe.ma" }
  s.social_media_url   = "http://twitter.com/dunkelstern"

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"

  s.source       = { :git => "git@github.com:anfema/ion-client-ios.git", :tag => "6.2.0" }
  s.source_files  = "ion-client/cache/*.swift", "ion-client/communication/*.swift", "ion-client/helper/*.swift", "ion-client/model/**/*.swift", "ion-client/search/*.swift"

  s.framework  = "Alamofire", "DEjson", "Markdown", "HashExtensions", "html5tokenizer", "Tarpit"

  s.dependency "Alamofire", "~> 4.7"
  s.dependency "DEjson", "~> 4.0"
  s.dependency "Markdown", "~> 4.0"
  s.dependency "HashExtensions", "~> 2.0"
  s.dependency "html5tokenizer", "~> 3.0"
  s.dependency "Tarpit", "~> 3.0"
  s.dependency "iso-rfc822-date", "~> 1.0"
  s.dependency "SQLite.swift", "~> 0.12"

  s.swift_version = '5.0'
end
