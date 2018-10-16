#
#  Be sure to run `pod spec lint SwCtDB.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "SwCtDB"
  s.version      = "0.0.6"
  s.summary      = "一个Swift版的Sqlite操作库"
  s.homepage     = "https://github.com/clint23/SwCtDB"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author             = { "clint" => "3243629382@qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/clint23/SwCtDB.git", :tag => "#{s.version}" }
  s.swift_version = '4.1'
  s.source_files  = "SwCtDB/SwCtDB/SwCtDB.swift"
  s.framework  = "UIKit"
  s.library   = "sqlite3"
  s.requires_arc = true
end
