require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require File.dirname(__FILE__) + '/lib/flvtool2/version.rb'

PKG_NAME      = 'flvtool2'
PKG_VERSION   = FLVTool2.version
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION.downcase.gsub(/\s/, '_')}"
PKG_DESTINATION = "../#{PKG_NAME}"
RELEASE_NAME  = "REL #{PKG_VERSION}"
RUBY_FORGE_PROJECT = PKG_NAME
RUBY_FORGE_USER    = 'inlet'

PKG_FILES = FileList[
  '[a-zA-Z]*',
  'bin/**/*', 
  'examples/**/*',
  'lib/**/*'
] - [
  'test',
  'flvtool2.exe',
  'pkg'
]

task :default => :all_packages
task :windows => [:make_exe, :zip]
task :all_packages => [:package, :windows]
task :release => [:all_packages, :tag_svn, :rubyforge]

task :make_exe do
  `exerb flvtool2.exy`
end

task :zip => :make_exe do
  files = %w{ flvtool2.exe LICENSE CHANGELOG README examples examples/tags.xml }
  `zip pkg/#{PKG_FILE_NAME}.zip #{files.join(' ')} -x .svn`
end

task :tag_svn do
  system("svn cp http://svn.inlet-media.de/svn/flvtool2/trunk http://svn.inlet-media.de/svn/flvtool2/tags/#{PKG_FILE_NAME} -m '* Tag release #{PKG_FILE_NAME}'")
end

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = 'Flash video (FLV) manipulation tool'
  s.description = <<-EOF
    FLVTool2 is a manipulation tool for Macromedia Flash Video files (FLV). It can calculate a lot of meta data, insert an onMetaData tag, cut FLV files, add cue points (onCuePoint), show the FLV structure and print meta data information in XML or YAML.
  EOF

  s.files = PKG_FILES.to_a.delete_if {|f| f.include?('.svn')}
  s.require_path = 'lib'

  s.bindir = 'bin'                               # Use these for applications.
  s.executables = ['flvtool2']
  s.default_executable = 'flvtool2'

  s.author = "Norman Timmler"
  s.email = "norman.timmler@inlet-media.de"
  s.homepage = "http://www.inlet-media.de/flvtool2"
  s.rubyforge_project = "flvtool2"
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
  pkg.need_zip = false
  pkg.need_tar = true
end

desc "Publish the release files to RubyForge."
task :rubyforge => [ :gem ] do
  `rubyforge login`
  system("rubyforge add_release #{PKG_NAME} #{PKG_NAME} 'REL #{PKG_VERSION}' pkg/#{PKG_NAME}-#{PKG_VERSION}.gem")
  system("rubyforge add_release #{PKG_NAME} #{PKG_NAME} 'REL #{PKG_VERSION}' pkg/#{PKG_NAME}-#{PKG_VERSION}.tgz")
  system("rubyforge add_release #{PKG_NAME} #{PKG_NAME} 'REL #{PKG_VERSION}' pkg/#{PKG_NAME}-#{PKG_VERSION}.zip -t i386")
end