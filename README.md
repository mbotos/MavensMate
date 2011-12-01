<h1>MavensMate</h1>
MavensMate is a TextMate bundle that aims to replicate the functionality of the Eclipse-based Force.com IDE. In its current state, MavensMate enables developers to create Salesforce.com projects, connect them to SVN, create certain types of metadata, and compile and retrieve metadata, all from TextMate.

<P>
<h2>Installation</h2>
<h3>Preparing TextMate for Ruby 1.9+</h3>

<p>In order for TextMate to run Ruby 1.9+, we'll need to do a little legwork:</p>  

<p>1. Install rvm (Ruby Version Manager) if you have not already:</p>
```
bash < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer )
```

<p>2. Install Ruby 1.9.2:</p>
```
rvm install 1.9.2
rvm use 1.9.2 --default 
```

<p>3. Update TextMate's osx-plist for Ruby 1.9:</p>
```
git clone git://github.com/kballard/osx-plist.git
cd osx-plist/ext/plist
ruby extconf.rb && make
cp plist.bundle /Applications/TextMate.app/Contents/SharedSupport/Support/lib/osx/
```

<p>4. Make TextMate aware that we want to use Ruby 1.9.2:</p>

><p>Prepend your Ruby 1.9.2 installation to your TextMate PATH shell variable. Your PATH shell variable should look something like:</p>

	/Users/username/.rvm/rubies/ruby-1.9.2-p290/usr/bin:/usr/sbin

><p>Create a TextMate shell variable named GEM_PATH and set it to the path of your newly installed 1.9.2 gems. Should look something like:</p>

	/Users/username/.rvm/gems/ruby-1.9.2-p290


<p>5. Now, let's install a couple of gems:</p>
```
gem install savon
gem install rubyzip
```
<p><b>*Note:</b> DO NOT use sudo to work with RVM gems (http://beginrescueend.com/rubies/rubygems)</p>

<p>6. Finally, we need to create a TextMate shell variable that tells MavensMate where to put your projects. Create a shell variable named FM_PROJECT_FOLDER and set it the location of your choice:</p>
```
/Users/username/development/projects
```

<P><img src="http://wearemavens.com/images/mm/path.png"/></P>

<h3>Finally! Installing MavensMate</h3>
<p>Installing MavensMate via Git (recommended)</p>
```
mkdir -p ~/Library/Application\ Support/TextMate/Bundles
cd ~/Library/Application\ Support/TextMate/Bundles
git clone git://github.com/joeferraro/MavensMate.tmbundle.git "MavensMate.tmbundle"
osascript -e 'tell app "TextMate" to reload bundles'
```

<p>Installing MavensMate manually</p>
<OL>
	<LI><A HREF="https://github.com/joeferraro/MavensMate/tarball/master">Download this project</A>
	<LI>Unzip and rename the parent directory to "MavensMate.tmbundle"
	<LI>Double click "MavensMate.tmbundle". TextMate will automatically install the bundle
	<LI>Open TextMate, go to Preferences --> Advanced --> Shell Variables and add a Shell Variable called "FM_PROJECT_FOLDER" with the value being the location where you'd like your Salesforce.com projects to reside (for example: '/Users/joe/Projects') [*notice the absolute path*] 
</OL>

</P> 

<P>
<h2>MavensMate Shortcut Keys (configurable)</h2>
><P>Open MavensMate:</P>

	Command + Option + Command + M

><P>Compile:</P>

	Command + Option + Command + C

</P>

<P>
<h2>Some extra goodies</h2>
<P>We recommend the following to augment MavensMate:</P>
<UL>
	<LI>ProjectPlus TextMate plugin >>> adds nifty SVN/Git icons to project folder/file icons
	<A HREF="http://ciaranwal.sh/projectplus">http://ciaranwal.sh/projectplus</A>
</UL>
</P>