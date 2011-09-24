<h1>MavensMate</h1>
MavensMate is a TextMate bundle that aims to replicate the functionality of the Eclipse-based Force.com IDE. In its current state, it allows one to create Salesforce.com projects, connect them to SVN, create certain types of metadata, and compile and retrieve metadata. 

<P>
	<img src="http://joe-ferraro.com/images/mavensmate1.png"/>
</P>

<P>
In order to use MavensMate, you will need the Force.com Migration Tool. To obtain the Force.com Migration Tool, go to "Setup -> Develop -> Tools" in your Salesforce.com org, download the zip and follow the instructions. It's also important to ensure your system environmental variables are set up correctly.
</P>

<P>
<h2>Prerequisites</h2>
<P>You will need the following to run MavensMate:
</P>
<UL>
	<LI>Apache Ant --> <A HREF="http://ant.apache.org/">http://ant.apache.org/</A>
	<LI>TextMate --> <A HREF="http://macromates.com/">http://macromates.com/</A>
	<LI>Subversion TextMate bundle (highly recommended) --> <A HREF="http://manual.macromates.com/en/bundles">http://manual.macromates.com/en/bundles</A>
	<LI>A Salesforce.com org --> <A HREF="http://developer.force.com/">http://developer.force.com/</A>
</UL>
<P>

<P>
<h2>Installation</h2>
<P>How To Install MavensMate</P>
<OL>
	<LI><A HREF="https://github.com/joeferraro/MavensMate/tarball/master">Download this project</A>
	<LI>Rename the parent directory to "MavensMate.tmbundle"
	<LI>Double click the "MavensMate.tmbundle". TextMate will automatically install the bundle
	<LI>Open TextMate, go to Preferences --> Advanced --> Shell Variables and add a Shell Variable called "FM_PROJECT_FOLDER" with the value being the location where you'd like your Salesforce.com projects to reside (for example: '/Users/joeferraro/Development/Projects/') [notice the absolute path & trailing slash. the quotations are unnecessary as well, unless you have a space in your path name] 
</OL>
</P>
<P>
		<img src="http://joe-ferraro.com/images/mavensmate2.png"/>
</P>

<P>
<H1>Quick Start</H1>
<UL>
	<LI>Open TextMate
	<LI>Choose the MavensMate Bundle and click "New Project" (or you can simply use control+option+N)
	<LI>Enter your project information
	<LI>Click "Create Project"
	<LI>Sit back and enjoy TextMate not eating up 800mb of your RAM	
</UL>
</P>
		
		
	
</P>