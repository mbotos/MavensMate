<h1>MavensMate</h1>
MavensMate is a TextMate bundle that aims to replicate the functionality of the Eclipse-based Force.com IDE. In its current state, MavensMate enables developers to create Salesforce.com projects, connect them to SVN, create certain types of metadata, and compile and retrieve metadata, all from TextMate.

<b>MavensMate has been updated to utilize keychain for security and direct calls to the Salesforce.com metadata API (instead of ANT) for performance</b>

<P>
<h2>Installation</h2>
<P>How To Install MavensMate</P>
<p>
<b>*MavensMate requires Ruby 1.9.2!*</b>
</p>

```
$ gem install savon
$ gem install rubyzip
```

<OL>
	<LI><A HREF="https://github.com/joeferraro/MavensMate/tarball/master">Download this project</A>
	<LI>Unzip and rename the parent directory to "MavensMate.tmbundle"
	<LI>Double click "MavensMate.tmbundle". TextMate will automatically install the bundle
	<LI>Open TextMate, go to Preferences --> Advanced --> Shell Variables and add a Shell Variable called "FM_PROJECT_FOLDER" with the value being the location where you'd like your Salesforce.com projects to reside (for example: '/Users/joe/Projects/') [*notice the absolute path*] 
</OL>
</P> 

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
<h2>Current Limitations</h2>
<UL>
	<LI>MavensMate currently utilizes the most basic developer-friendly package.xml manifest: Apex Classes, VF Components, VF Pages, Static Resources, and Apex Triggers. On the roadmap is the ability to create a custom package.xml by selecting the elements of metadata you'd like to be part of your Salesforce.com project.
	<LI>Running tests from MavensMate is currently not possible (but on the roadmap)
	<LI>Force.com IDE's "Deploy to Server" functionality that enables easy deployment from sandbox --> prod, with diff support is not available in MavensMate *at this time*
</UL>
</P>

<P>
<h2>Prerequisites</h2>

<P>You will need the following to run MavensMate:</P>
<UL>
	<LI>TextMate --> <A HREF="http://macromates.com/">http://macromates.com/</A>
	<LI>Savon --> <A HREF="https://github.com/rubiii/savon">https://github.com/rubiii/savon</A>
	<LI>RubyZip --> <A HREF="http://rubygems.org/gems/rubyzip">http://rubygems.org/gems/rubyzip</A>
	<LI>Subversion TextMate bundle (highly recommended) --> <A HREF="http://manual.macromates.com/en/bundles">http://manual.macromates.com/en/bundles</A> 
	<LI>ProjectPlus TextMate plugin (highly recommended, if you want nifty git/svn file status icons) --> <A HREF="http://ciaranwal.sh/projectplus">http://ciaranwal.sh/projectplus</A>	
	<LI>A Salesforce.com org --> <A HREF="http://developer.force.com/">http://developer.force.com/</A>
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