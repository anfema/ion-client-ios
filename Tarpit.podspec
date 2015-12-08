Pod::Spec.new do |s|
  s.name         = "Tarpit"
  s.version      = "1.0.1"
  s.summary      = "TAR-file unpacker in swift."
  s.description  = <<-DESC
                   TAR-file unpacker in swift.
                   
                   Unpacks GNU "star" files from stream, file or NSData representations
                   DESC

  s.homepage     = "https://github.com/anfema/amp-ios-client"
  s.license      = { :type => "BSD", :file => "tarpit/LICENSE.txt" }
  s.author             = { "Johannes Schriewer" => "j.schriewer@anfe.ma" }
  s.social_media_url   = "http://twitter.com/dunkelstern"

  s.ios.deployment_target = "8.4"
  s.osx.deployment_target = "10.10"

  s.source       = { :git => "git@github.com:anfema/amp-ios-client.git", :tag => "tar-1.0.1" }
  s.source_files  = "tarpit/src/*.swift"  
end
