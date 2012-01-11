<h1>MavensMate</h1>
MavensMate is a TextMate bundle that aims to replicate the functionality of the Eclipse-based Force.com IDE.
<UL>
	<LI>Create Salesforce.com projects with specific package metadata (and import to SVN)
	<LI>Checkout Salesforce.com projects from SVN
	<LI>Create & compile Apex Classes, Apex Trigger, Visualforce Pages, and Visualforce Components
	<LI>Compile and retrieve other Salesforce.com metadata
	<LI>Run Apex test methods and visualize test successes/failures & coverage
	<LI>Supports code completion for SObject fields & Apex primitive methods (Alpha)
</UL> 

<P>
<h2>Clean Install</h2>
<p></p>
```
$ sudo gem install rails
$ sudo gem install builder
$ sudo gem install savon
$ sudo gem install rubyzip
```
<p></p>
```
$ mkdir -p ~/Library/Application\ Support/TextMate/Bundles
$ cd ~/Library/Application\ Support/TextMate/Bundles
$ git clone git://github.com/joeferraro/MavensMate.git "MavensMate.tmbundle"
$ osascript -e 'tell app "TextMate" to reload bundles'
```

<p>Open TextMate, go to Preferences --> Advanced --> Shell Variables and add a Shell Variable called "FM_PROJECT_FOLDER" with the value being the location where you'd like your Salesforce.com projects to reside (for example: '/Users/joe/Projects') [*notice the absolute path*]</p>
```
/Users/username/development/projects
```
<P>*FM_PROJECT_FOLDER is the only TextMate shell variable required by MavensMate*</P>
<P><img src="http://wearemavens.com/images/mm/path3.png"/></P>

<h3>IMPORTANT</h3>
<P>If you get a ruby "constantize" exception when trying to create or checkout a project, it's likely a gem dependency issue. Ensure you've installed rails, builder, savon, and rubyzip.</P>

<h2>Update</h2>
<p></p>
```
$ cd ~/Library/Application\ Support/TextMate/Bundles
$ rm -rf ~/Library/Application\ Support/TextMate/Bundles/MavensMate.tmbundle
$ git clone git://github.com/joeferraro/MavensMate.git "MavensMate.tmbundle"
$ osascript -e 'tell app "TextMate" to reload bundles'
```

</P> 

<P>
<h2>MavensMate Shortcut Keys (configurable)</h2>
<P>Open MavensMate options:</P>

	Control + Option + Command + M

<P>Compile current metadata:</P>

	Control + Option + Command + C

<P>Code Completion:</P>

	Shift + Tab
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
<h2>Project Wizard</h2>
<P><img src="http://wearemavens.com/images/mm/wizard.png"/></P>
<h2>Apex Test Runner</h2>
<P><img src="http://wearemavens.com/images/mm/test2.png"/></P>
<h2>Code Completion</h2>
<P><img src="http://wearemavens.com/images/mm/completion2.png"/></P>
<h2>Options Dialog</h2>
<P><img src="http://wearemavens.com/images/mm/options.png"/></P>
</p>