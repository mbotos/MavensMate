<h1>MavensMate</h1>
MavensMate is a TextMate bundle that aims to replicate the functionality of the Eclipse-based Force.com IDE. In its current state, it allows one to create Salesforce.com projects, create certain types of metadata, and compile and retrieve metadata. 

<P>
In order to use MavensMate, you will need the Force.com Migration Tool. To obtain the Force.com Migration Tool, go to "Setup -> Develop -> Tools" in your Salesforce.com org, download the zip and follow the instructions.
</P>

<P>
<h2>Prerequisites</h2>
<P>You will need the following to run MavensMate:
</P>
<UL>
	<LI>Apache Ant
	<LI>TextMate
	<LI>Subversion TextMate bundle (highly recommended)
	<LI>A Salesforce.com org
</UL>
<P>

<P>
<h2>Installation</h2>
<P>How To Install MavensMate</P>
<OL>
	<LI>Download this project
	<LI>Rename the parent directory to "MavensMate.tmbundle"
	<LI>Double click the "MavensMate.tmbundle". TextMate will automatically install the bundle
	<LI>Open TextMate, go to Preferences --> Advanced --> Shell Variables and add a Shell Variable called "FM_PROJECT_FOLDER" with the value being the location where you'd like your Salesforce.com projects to reside (for example: '/Users/joeferraro/Development/Projects/') [notice the absolute path & trailing slash. the quotations are unnecessary as well, unless you have a space in your path name] 
	<LI>OK, you're ready to roll
</OL>
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