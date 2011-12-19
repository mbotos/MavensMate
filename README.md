<h1>MavensMate</h1>
MavensMate is a TextMate bundle that aims to replicate the functionality of the Eclipse-based Force.com IDE. In its current state, MavensMate enables developers to create Salesforce.com projects, connect them to SVN, create certain types of metadata, and compile and retrieve metadata, all from TextMate.

<P>
<h2>Installation</h2>
```
$ gem install builder
$ gem install savon
$ gem install rubyzip
```

<p>Create a TextMate shell variable that tells MavensMate where to put your projects. Create a shell variable named FM_PROJECT_FOLDER and set it the location of your choice:</p>
```
/Users/username/development/projects
```

<P><img src="http://wearemavens.com/images/mm/path.png"/></P>

<p>Installing MavensMate via Git (recommended)</p>
```
$ mkdir -p ~/Library/Application\ Support/TextMate/Bundles
$ cd ~/Library/Application\ Support/TextMate/Bundles
$ git clone git://github.com/joeferraro/MavensMate.git "MavensMate.tmbundle"
$ osascript -e 'tell app "TextMate" to reload bundles'
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
<P>Open MavensMate options:</P>

	Control + Option + Command + M

<P>Compile current metadata:</P>

	Control + Option + Command + C

</P>

<P>
<h2>Some extra goodies</h2>
<P>We recommend the following to augment MavensMate:</P>
<UL>
	<LI>ProjectPlus TextMate plugin >>> adds nifty SVN/Git icons to project folder/file icons
	<A HREF="http://ciaranwal.sh/projectplus">http://ciaranwal.sh/projectplus</A>
</UL>
</P>

<p>
<h2>Screencast</h2>
<p><a href="http://vimeo.com/mavens/review/33363307/c072a3df51">http://vimeo.com/mavens/review/33363307/c072a3df51</a></p>
</p>	

<P>
<h2>Screenshots</h2>
<P><img src="http://wearemavens.com/images/mm/project.png"/></P>
<P><img src="http://wearemavens.com/images/mm/options.png"/></P>
</p>