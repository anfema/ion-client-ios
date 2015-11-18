Pod::Spec.new do |s|
  s.name         = "html5parser"
  s.version      = "1.0.0"
  s.summary      = "HTML5 compliant tokenizer in pure swift."
  s.description  = <<-DESC
                    HTML5 compliant tokenizer in pure swift. Only UTF-8 charset is supported.

                    Unsupported:
                    -> DOCTYPE is parsed as bogus comment
                    -> Script and raw text (style tags) are not supported (wrap them in <![CDATA[ ]]> to use them)
                    -> Tree generation phase is not implemented (no javascript execution)
                    -> Compound named character entities are missing
                   DESC

  s.homepage     = "https://github.com/anfema/amp-ios-client"
  s.license      = { :type => "BSD", :file => "html5parser/LICENSE.txt" }
  s.author             = { "Johannes Schriewer" => "j.schriewer@anfe.ma" }
  s.social_media_url   = "http://twitter.com/dunkelstern"

  s.ios.deployment_target = "8.4"
  s.osx.deployment_target = "10.10"

  s.source       = { :git => "git@github.com:anfema/amp-ios-client.git", :tag => "html-1.0.0" }
  s.source_files  = "html5parser/html5parser/*.swift"
  
end
