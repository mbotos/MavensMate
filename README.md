<h1>MavensMate</h1>
MavensMate is a TextMate bundle that aims to replicate the functionality of the Eclipse-based Force.com IDE. In its current state, MavensMate enables developers to create Salesforce.com projects, connect them to SVN, create certain types of metadata, and compile and retrieve metadata, all from TextMate.

<b>MavensMate has been recently updated to utilize keychain for security and direct calls to the Salesforce.com metadata API (instead of ANT) for performance</b>

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
<ol>
	<li>Prepend your Ruby 1.9.2 installtion to your PATH shell variable. Your PATH shell variable should look something like: 
	````
	/Users/username/.rvm/rubies/ruby-1.9.2-p290/usr/bin:/usr/sbin
	````
	<li>Create a shell variable named GEM_PATH and set it to the path of your newly installed 1.9.2 gems. Something like: 
	````
	/Users/username/.rvm/gems/ruby-1.9.2-p290
	````
</ol>
 

<p>5. Now, let's install a couple of gems:</p>
```
gem install savon
gem install rubyzip
```
<p><b>*Note:</b> DO NOT use sudo to work with RVM gems (http://beginrescueend.com/rubies/rubygems)</p>

</p>6. Finally, we need to create a TextMate shell variable that tells MavensMate where to put your projects. Create a shell variable named FM_PROJECT_FOLDER and set it the location of your choice: </p>
	````
	/Users/username/development/projects
	````


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
<h2>Current Features</h2>
<UL>
	<LI>Create a new Salesforce.com project (and import to SVN & checkout working copy in the same step [Optional])
	<LI>Checkout a Salesforce.com project from SVN (adds "Force.com Nature" to the project as well (for you Eclipse converters))
	<LI>Create a new Apex Classes, Apex Triggers, Visualforce Pages, & Visualforce Components
	<LI>Compile your Salesforce.com metadata (obviously)
	<LI>Refresh your project from the server
	<LI>Apex/Visualforce Syntax Highlighting (thanks @quintonwall)
	<LI>Fantastic keyboard shortcut support: use control + option + command + M to bring up MavensMate features
</UL>
</P>

<P>
<h2>Some extra goodies</h2>

<P>We recommend the following to augment MavensMate:</P>
<UL>
	<LI>ProjectPlus TextMate plugin >>> adds nifty SVN/Git icons to project folder/file icons
	<A HREF="http://ciaranwal.sh/projectplus">http://ciaranwal.sh/projectplus</A>
</UL>
</P>

<P>
	<img src="http://joe-ferraro.com/images/mavensmate2.png"/>
</P>

<P>
<H1>Quick Start</H1>
<OL>
	<LI>Open TextMate
	<LI>Choose the MavensMate Bundle and click "New Project" (or you can simply use control+option+command+M and selected "New Project") (**please note:TextMate requires a textfile be open in order to perform bundle operations, so if the MavensMate bundle options are grayed out under Bundles --> MavensMate, simply open a blank text file [command+N])
	<LI>Enter your project information (SVN information is optional)
	<LI>Click "Create Project"
	<LI>Sit back and enjoy TextMate not eating up 800mb of your RAM	
</OL>
</P>

<P>
<h2>Current Limitations</h2>
<UL>
	<LI>MavensMate currently utilizes the most basic developer-friendly package.xml manifest: Apex Classes, VF Components, VF Pages, Static Resources, and Apex Triggers. On the roadmap is the ability to create a custom package.xml by selecting the elements of metadata you'd like to be part of your Salesforce.com project.
	<LI>Running tests from MavensMate is currently not possible (but on the roadmap)
	<LI>Force.com IDE's "Deploy to Server" functionality that enables easy deployment from sandbox --> prod, with diff support is not available in MavensMate *at this time*
</UL>
</P>

<H1>Screenshots</H1>
<P>
	<img src="http://wearemavens.com/mm/mavensmate1.png"/>
</P>
<p>
	<img src="http://joe-ferraro.com/images/mavensmate7.png"/>
</p>
<P>
	<img src="http://wearemavens.com/mm/mavensmate5.png"/>
</P>
<P>
	<img src="http://wearemavens.com/mm/mavensmate6.png"/>
</P>
<P>
	<img src="http://joe-ferraro.com/images/mavensmate4.png"/>
</P>